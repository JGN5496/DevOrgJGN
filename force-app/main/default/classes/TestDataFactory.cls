/**
 * @description Centralized factory for creating test data with sensible defaults.
 *              All methods accept a doInsert flag for flexibility.
 *              Bulk methods create multiple records; single-record methods delegate to bulk.
 */
@isTest
public class TestDataFactory {

    // ─── Accounts ─────────────────────────────────────────────────────────

    public static List<Account> createAccounts(Integer count, Boolean doInsert) {
        List<Account> accounts = new List<Account>();
        String uniqueSuffix = String.valueOf(DateTime.now().getTime());
        for (Integer i = 0; i < count; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + uniqueSuffix + ' ' + i,
                BillingCity = 'San Francisco',
                BillingState = 'CA',
                BillingCountry = 'USA',
                Industry = 'Technology',
                Type = 'Customer'
            ));
        }
        if (doInsert) {
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.DuplicateRuleHeader.AllowSave = true;
            Database.insert(accounts, dml);
        }
        return accounts;
    }

    public static Account createAccount(Boolean doInsert) {
        return createAccounts(1, doInsert)[0];
    }

    // ─── Orders ───────────────────────────────────────────────────────────

    public static List<Order> createOrders(List<Account> accounts, Integer countPerAccount, String status, Boolean doInsert) {
        List<Order> orders = new List<Order>();
        Integer idx = 0;
        Id standardPricebookId = Test.getStandardPricebookId();
        
        for (Account acc : accounts) {
            for (Integer i = 0; i < countPerAccount; i++) {
                orders.add(new Order(
                    AccountId = acc.Id,
                    Status = 'Draft',
                    EffectiveDate = Date.today(),
                    Pricebook2Id = standardPricebookId,
                    Name = 'Test Order ' + idx
                ));
                idx++;
            }
        }
        
        if (doInsert) {
            insert orders;
            // Note: Orders requiring non-Draft status must have OrderItems added first
            // Call this method with 'Draft' status, then add OrderItems, then update status separately
        }
        return orders;
    }

    public static Order createOrder(Account acc, String status, Boolean doInsert) {
        return createOrders(new List<Account>{ acc }, 1, status, doInsert)[0];
    }
    
    /**
     * Activate an Order (change status from Draft to Activated)
     * Note: Order must have at least one OrderItem before activation
     */
    public static void activateOrder(Order ord) {
        ord.Status = 'Activated';
        update ord;
    }

    // ─── OrderItems ───────────────────────────────────────────────────────

    public static List<OrderItem> createOrderItems(Order ord, Product2 product, PricebookEntry pbe, Integer count, Decimal quantity, Decimal unitPrice, Boolean doInsert) {
        List<OrderItem> items = new List<OrderItem>();
        for (Integer i = 0; i < count; i++) {
            items.add(new OrderItem(
                OrderId = ord.Id,
                Product2Id = product.Id,
                PricebookEntryId = pbe.Id,
                Quantity = quantity,
                UnitPrice = unitPrice
            ));
        }
        // Bulk insert all items at once
        if (doInsert && !items.isEmpty()) {
            insert items;
        }
        return items;
    }
    
    /**
     * Bulk creates OrderItems for multiple Orders
     */
    public static List<OrderItem> createOrderItemsForOrders(List<Order> orders, Product2 product, PricebookEntry pbe, Decimal quantity, Decimal unitPrice, Boolean doInsert) {
        List<OrderItem> items = new List<OrderItem>();
        for (Order ord : orders) {
            items.add(new OrderItem(
                OrderId = ord.Id,
                Product2Id = product.Id,
                PricebookEntryId = pbe.Id,
                Quantity = quantity,
                UnitPrice = unitPrice
            ));
        }
        if (doInsert && !items.isEmpty()) {
            insert items;
        }
        return items;
    }

    // ─── Products & Pricebooks ────────────────────────────────────────────

    public static Product2 createProduct(Boolean doInsert) {
        Product2 prod = new Product2(
            Name = 'Test Product',
            IsActive = true,
            ProductCode = 'TEST-PROD-' + String.valueOf(DateTime.now().getTime())
        );
        if (doInsert) insert prod;
        return prod;
    }

    public static PricebookEntry createPricebookEntry(Product2 product, Decimal unitPrice, Boolean doInsert) {
        // Get standard pricebook
        Pricebook2 standardPB = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPB.Id,
            Product2Id = product.Id,
            UnitPrice = unitPrice,
            IsActive = true
        );
        if (doInsert) insert pbe;
        return pbe;
    }

    // ─── Field Override Pattern ────────────────────────────────────────────

    public static Account createAccount(Map<String, Object> fieldOverrides, Boolean doInsert) {
        Account acc = new Account(
            Name = 'Test Account',
            Industry = 'Technology'
        );
        for (String fieldName : fieldOverrides.keySet()) {
            acc.put(fieldName, fieldOverrides.get(fieldName));
        }
        if (doInsert) insert acc;
        return acc;
    }
}