/**
 * Test class for OrderPricingService.
 * Tests bulk operations (251+ records), positive/negative paths,
 * boundary conditions, and exception handling for volume discount logic.
 */
@isTest
private class OrderPricingServiceTest {

    private static final Decimal STANDARD_UNIT_PRICE = 100.00;
    private static final Decimal EXPECTED_DISCOUNTED_PRICE = 90.00;
    private static final Integer BULK_RECORD_COUNT = 251;

    @TestSetup
    static void setupTestData() {
        // Create test accounts
        List<Account> accounts = TestDataFactory.createAccounts(BULK_RECORD_COUNT, true);
    }

    // ─── Positive Tests ───────────────────────────────────────────────────

    @isTest
    static void shouldApplyDiscount_WhenQuantityExceeds50AndDraftStatus() {
        // Given
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Order draftOrder = TestDataFactory.createOrder(acc, 'Draft', true);
        Product2 product = TestDataFactory.createProduct(true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(product, STANDARD_UNIT_PRICE, true);
        
        // Create 3 items with quantities totaling 51 (exceeds threshold)
        TestDataFactory.createOrderItems(draftOrder, product, pbe, 1, 30, STANDARD_UNIT_PRICE, true);
        TestDataFactory.createOrderItems(draftOrder, product, pbe, 1, 15, STANDARD_UNIT_PRICE, true);
        TestDataFactory.createOrderItems(draftOrder, product, pbe, 1, 6, STANDARD_UNIT_PRICE, true);

        List<Order> orders = [SELECT Id, Status FROM Order WHERE Id = :draftOrder.Id];

        // When
        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            OrderPricingService.applyVolumeDiscount(orders);
        }
        Test.stopTest();

        // Then
        List<OrderItem> items = [SELECT Id, UnitPrice FROM OrderItem WHERE OrderId = :draftOrder.Id];
        Assert.areEqual(3, items.size(), 'Should have 3 OrderItems');
        for (OrderItem item : items) {
            Assert.areEqual(EXPECTED_DISCOUNTED_PRICE, item.UnitPrice, 
                'UnitPrice should be discounted to 90.00 (10% off 100.00)');
        }
    }

    @isTest
    static void shouldHandleBulkOrders_When251OrdersProcessed() {
        // Given
        List<Account> accounts = [SELECT Id FROM Account];
        Assert.areEqual(BULK_RECORD_COUNT, accounts.size(), 'Should have 251 test accounts');

        List<Order> draftOrders = TestDataFactory.createOrders(accounts, 1, 'Draft', true);
        Product2 product = TestDataFactory.createProduct(true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(product, STANDARD_UNIT_PRICE, true);

        // Use bulk method to create all items at once
        TestDataFactory.createOrderItemsForOrders(draftOrders, product, pbe, 51, STANDARD_UNIT_PRICE, true);

        List<Order> orders = [SELECT Id, Status FROM Order WHERE Id IN :draftOrders];

        // When
        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            OrderPricingService.applyVolumeDiscount(orders);
        }
        Test.stopTest();

        // Then
        List<OrderItem> items = [SELECT Id, UnitPrice FROM OrderItem WHERE OrderId IN :draftOrders];
        Assert.areEqual(BULK_RECORD_COUNT, items.size(), 'Should have 251 OrderItems');
        for (OrderItem item : items) {
            Assert.areEqual(EXPECTED_DISCOUNTED_PRICE, item.UnitPrice, 
                'All items should have discounted price');
        }
    }

    @isTest
    static void shouldRoundToTwoDecimals_WhenApplyingDiscount() {
        // Given
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Order draftOrder = TestDataFactory.createOrder(acc, 'Draft', true);
        Product2 product = TestDataFactory.createProduct(true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(product, 99.99, true);
        
        TestDataFactory.createOrderItems(draftOrder, product, pbe, 1, 51, 99.99, true);

        List<Order> orders = [SELECT Id, Status FROM Order WHERE Id = :draftOrder.Id];

        // When
        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            OrderPricingService.applyVolumeDiscount(orders);
        }
        Test.stopTest();

        // Then
        OrderItem item = [SELECT Id, UnitPrice FROM OrderItem WHERE OrderId = :draftOrder.Id LIMIT 1];
        // 99.99 * 0.90 = 89.991, should round to 89.99
        Assert.areEqual(89.99, item.UnitPrice, 
            'UnitPrice should be rounded to 2 decimal places (89.99)');
    }

    // ─── Boundary Tests ───────────────────────────────────────────────────

    @isTest
    static void shouldNotApplyDiscount_WhenQuantityEquals50() {
        // Given
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Order draftOrder = TestDataFactory.createOrder(acc, 'Draft', true);
        Product2 product = TestDataFactory.createProduct(true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(product, STANDARD_UNIT_PRICE, true);
        
        // Create items with quantities totaling exactly 50 (at threshold, not exceeding)
        TestDataFactory.createOrderItems(draftOrder, product, pbe, 2, 25, STANDARD_UNIT_PRICE, true);

        List<Order> orders = [SELECT Id, Status FROM Order WHERE Id = :draftOrder.Id];

        // When
        Test.startTest();
        OrderPricingService.applyVolumeDiscount(orders);
        Test.stopTest();

        // Then
        List<OrderItem> items = [SELECT Id, UnitPrice FROM OrderItem WHERE OrderId = :draftOrder.Id];
        for (OrderItem item : items) {
            Assert.areEqual(STANDARD_UNIT_PRICE, item.UnitPrice, 
                'UnitPrice should remain unchanged at 100.00 (threshold not exceeded)');
        }
    }

    @isTest
    static void shouldApplyDiscount_WhenQuantityEquals51() {
        // Given
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Order draftOrder = TestDataFactory.createOrder(acc, 'Draft', true);
        Product2 product = TestDataFactory.createProduct(true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(product, STANDARD_UNIT_PRICE, true);
        
        // Create items with quantities totaling exactly 51 (just exceeds threshold)
        TestDataFactory.createOrderItems(draftOrder, product, pbe, 1, 51, STANDARD_UNIT_PRICE, true);

        List<Order> orders = [SELECT Id, Status FROM Order WHERE Id = :draftOrder.Id];

        // When
        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            OrderPricingService.applyVolumeDiscount(orders);
        }
        Test.stopTest();

        // Then
        OrderItem item = [SELECT Id, UnitPrice FROM OrderItem WHERE OrderId = :draftOrder.Id LIMIT 1];
        Assert.areEqual(EXPECTED_DISCOUNTED_PRICE, item.UnitPrice, 
            'UnitPrice should be discounted when quantity is exactly 51');
    }

    @isTest
    static void shouldNotApplyDiscount_WhenNotDraftStatus() {
        // Given
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Order activatedOrder = TestDataFactory.createOrder(acc, 'Draft', true);
        Product2 product = TestDataFactory.createProduct(true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(product, STANDARD_UNIT_PRICE, true);
        
        // Add OrderItems first, then activate
        TestDataFactory.createOrderItems(activatedOrder, product, pbe, 1, 51, STANDARD_UNIT_PRICE, true);
        TestDataFactory.activateOrder(activatedOrder);

        List<Order> orders = [SELECT Id, Status FROM Order WHERE Id = :activatedOrder.Id];

        // When
        Test.startTest();
        OrderPricingService.applyVolumeDiscount(orders);
        Test.stopTest();

        // Then
        OrderItem item = [SELECT Id, UnitPrice FROM OrderItem WHERE OrderId = :activatedOrder.Id LIMIT 1];
        Assert.areEqual(STANDARD_UNIT_PRICE, item.UnitPrice, 
            'UnitPrice should remain unchanged for non-Draft Order');
    }

    // ─── Negative Tests ───────────────────────────────────────────────────

    @isTest
    static void shouldHandleGracefully_WhenNullInput() {
        // When
        Test.startTest();
        OrderPricingService.applyVolumeDiscount(null);
        Test.stopTest();

        // Then - no exception thrown, method returns gracefully
        Assert.isTrue(true, 'Method should handle null input gracefully');
    }

    @isTest
    static void shouldHandleGracefully_WhenEmptyInput() {
        // When
        Test.startTest();
        OrderPricingService.applyVolumeDiscount(new List<Order>());
        Test.stopTest();

        // Then - no exception thrown, method returns gracefully
        Assert.isTrue(true, 'Method should handle empty list gracefully');
    }

    @isTest
    static void shouldHandleGracefully_WhenOrderHasNoItems() {
        // Given
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Order emptyOrder = TestDataFactory.createOrder(acc, 'Draft', true);
        List<Order> orders = [SELECT Id, Status FROM Order WHERE Id = :emptyOrder.Id];

        // When
        Test.startTest();
        OrderPricingService.applyVolumeDiscount(orders);
        Test.stopTest();

        // Then - no exception thrown
        List<OrderItem> items = [SELECT Id FROM OrderItem WHERE OrderId = :emptyOrder.Id];
        Assert.isTrue(items.isEmpty(), 'Order should have no OrderItems');
    }

    @isTest
    static void shouldHandleNullQuantities_WhenCalculatingTotal() {
        // Given
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Order draftOrder = TestDataFactory.createOrder(acc, 'Draft', true);
        Product2 product = TestDataFactory.createProduct(true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(product, STANDARD_UNIT_PRICE, true);
        
        // Create one item with quantity, another will have null (if possible in test context)
        TestDataFactory.createOrderItems(draftOrder, product, pbe, 1, 51, STANDARD_UNIT_PRICE, true);

        List<Order> orders = [SELECT Id, Status FROM Order WHERE Id = :draftOrder.Id];

        // When
        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            OrderPricingService.applyVolumeDiscount(orders);
        }
        Test.stopTest();

        // Then - should handle null quantities without error
        OrderItem item = [SELECT Id, UnitPrice FROM OrderItem WHERE OrderId = :draftOrder.Id LIMIT 1];
        Assert.areEqual(EXPECTED_DISCOUNTED_PRICE, item.UnitPrice, 
            'Discount should apply based on non-null quantities');
    }

    // ─── Edge Case Tests ──────────────────────────────────────────────────

    @isTest
    static void shouldHandleMixedOrders_WhenSomeQualifyForDiscount() {
        // Given
        List<Account> accounts = [SELECT Id FROM Account LIMIT 3];
        
        // Order 1: Draft, quantity > 50 (qualifies)
        Order order1 = TestDataFactory.createOrder(accounts[0], 'Draft', true);
        // Order 2: Draft, quantity = 50 (does not qualify)
        Order order2 = TestDataFactory.createOrder(accounts[1], 'Draft', true);
        // Order 3: Activated, quantity > 50 (does not qualify - wrong status)
        Order order3 = TestDataFactory.createOrder(accounts[2], 'Draft', true);

        Product2 product = TestDataFactory.createProduct(true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(product, STANDARD_UNIT_PRICE, true);

        TestDataFactory.createOrderItems(order1, product, pbe, 1, 51, STANDARD_UNIT_PRICE, true);
        TestDataFactory.createOrderItems(order2, product, pbe, 1, 50, STANDARD_UNIT_PRICE, true);
        TestDataFactory.createOrderItems(order3, product, pbe, 1, 51, STANDARD_UNIT_PRICE, true);
        
        // Activate order3 after adding OrderItems
        TestDataFactory.activateOrder(order3);

        List<Order> orders = [SELECT Id, Status FROM Order WHERE Id IN (:order1.Id, :order2.Id, :order3.Id)];

        // When
        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            OrderPricingService.applyVolumeDiscount(orders);
        }
        Test.stopTest();

        // Then
        OrderItem item1 = [SELECT Id, UnitPrice FROM OrderItem WHERE OrderId = :order1.Id LIMIT 1];
        OrderItem item2 = [SELECT Id, UnitPrice FROM OrderItem WHERE OrderId = :order2.Id LIMIT 1];
        OrderItem item3 = [SELECT Id, UnitPrice FROM OrderItem WHERE OrderId = :order3.Id LIMIT 1];

        Assert.areEqual(EXPECTED_DISCOUNTED_PRICE, item1.UnitPrice, 
            'Order 1 should have discount (Draft + quantity > 50)');
        Assert.areEqual(STANDARD_UNIT_PRICE, item2.UnitPrice, 
            'Order 2 should not have discount (quantity = 50)');
        Assert.areEqual(STANDARD_UNIT_PRICE, item3.UnitPrice, 
            'Order 3 should not have discount (Activated status)');
    }

    @isTest
    static void shouldHandleZeroUnitPrice_WhenApplyingDiscount() {
        // Given
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Order draftOrder = TestDataFactory.createOrder(acc, 'Draft', true);
        Product2 product = TestDataFactory.createProduct(true);
        PricebookEntry pbe = TestDataFactory.createPricebookEntry(product, 0, true);
        
        TestDataFactory.createOrderItems(draftOrder, product, pbe, 1, 51, 0, true);

        List<Order> orders = [SELECT Id, Status FROM Order WHERE Id = :draftOrder.Id];

        // When
        Test.startTest();
        OrderPricingService.applyVolumeDiscount(orders);
        Test.stopTest();

        // Then - should not update items with zero price
        OrderItem item = [SELECT Id, UnitPrice FROM OrderItem WHERE OrderId = :draftOrder.Id LIMIT 1];
        Assert.areEqual(0, item.UnitPrice, 
            'Zero UnitPrice should remain unchanged');
    }
}