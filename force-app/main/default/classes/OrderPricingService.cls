/**
 * Service class for Order pricing business logic.
 * Provides volume discount calculation and application for Orders and OrderItems.
 */
public with sharing class OrderPricingService {

    // ─── Constants ───────────────────────────────────────────────────────
    private static final String ERROR_NULL_INPUT = 'Input cannot be null or empty.';
    private static final Integer VOLUME_DISCOUNT_THRESHOLD = 50;
    private static final Decimal DISCOUNT_RATE = 0.10;
    private static final Integer DECIMAL_PLACES = 2;
    private static final String ORDER_STATUS_DRAFT = 'Draft';

    // ─── Public API ──────────────────────────────────────────────────────

    /**
     * Applies a 10% volume discount to OrderItems when the total quantity across
     * all items for an Order exceeds 50 units. Only applies to Orders in Draft status.
     * 
     * @param orders List of Order records to process for volume discounts
     * @throws OrderPricingServiceException if processing fails
     * @example
     * List<Order> orders = [SELECT Id, Status FROM Order WHERE Id IN :orderIds];
     * OrderPricingService.applyVolumeDiscount(orders);
     */
    public static void applyVolumeDiscount(List<Order> orders) {
        // Guard clause
        if (orders == null || orders.isEmpty()) {
            return;
        }

        // Extract Order Ids
        Set<Id> orderIds = new Set<Id>();
        Map<Id, String> orderStatusById = new Map<Id, String>();
        
        for (Order ord : orders) {
            if (ord.Id != null) {
                orderIds.add(ord.Id);
                orderStatusById.put(ord.Id, ord.Status);
            }
        }

        if (orderIds.isEmpty()) {
            return;
        }

        // Query OrderItems for all Orders in a single SOQL
        List<OrderItem> allOrderItems = [
            SELECT Id, OrderId, Quantity, UnitPrice
            FROM OrderItem
            WHERE OrderId IN :orderIds
            WITH USER_MODE
        ];

        if (allOrderItems.isEmpty()) {
            return;
        }

        // Group OrderItems by OrderId for efficient processing
        Map<Id, List<OrderItem>> orderItemsByOrderId = groupOrderItemsByOrderId(allOrderItems);

        // Calculate discounts and collect items to update
        List<OrderItem> itemsToUpdate = new List<OrderItem>();

        for (Id orderId : orderItemsByOrderId.keySet()) {
            List<OrderItem> orderItems = orderItemsByOrderId.get(orderId);
            String orderStatus = orderStatusById.get(orderId);

            // Calculate total quantity for this Order
            Decimal totalQuantity = calculateTotalQuantity(orderItems);

            // Apply discount only if threshold exceeded AND Order is in Draft status
            if (totalQuantity > VOLUME_DISCOUNT_THRESHOLD && orderStatus == ORDER_STATUS_DRAFT) {
                for (OrderItem item : orderItems) {
                    if (item.UnitPrice != null && item.UnitPrice > 0) {
                        Decimal discountedPrice = item.UnitPrice * (1 - DISCOUNT_RATE);
                        item.UnitPrice = discountedPrice.setScale(DECIMAL_PLACES, RoundingMode.HALF_UP);
                        itemsToUpdate.add(item);
                    }
                }
            }
        }

        // Update OrderItems in bulk if any discounts applied
        if (!itemsToUpdate.isEmpty()) {
            try {
                update itemsToUpdate;
            } catch (DmlException e) {
                throw new OrderPricingServiceException(
                    'Failed to update OrderItem records: ' + e.getMessage(),
                    e
                );
            }
        }
    }

    // ─── Private Helpers ─────────────────────────────────────────────────

    /**
     * Groups OrderItems by their parent OrderId
     * @param orderItems List of OrderItems to group
     * @return Map of OrderId to List of OrderItems
     */
    private static Map<Id, List<OrderItem>> groupOrderItemsByOrderId(List<OrderItem> orderItems) {
        Map<Id, List<OrderItem>> orderItemsByOrderId = new Map<Id, List<OrderItem>>();

        for (OrderItem item : orderItems) {
            if (!orderItemsByOrderId.containsKey(item.OrderId)) {
                orderItemsByOrderId.put(item.OrderId, new List<OrderItem>());
            }
            orderItemsByOrderId.get(item.OrderId).add(item);
        }

        return orderItemsByOrderId;
    }

    /**
     * Calculates the total quantity across all OrderItems
     * @param orderItems List of OrderItems for a single Order
     * @return Total quantity sum (defaults to 0 if all null)
     */
    private static Decimal calculateTotalQuantity(List<OrderItem> orderItems) {
        Decimal total = 0;

        for (OrderItem item : orderItems) {
            if (item.Quantity != null) {
                total += item.Quantity;
            }
        }

        return total;
    }

    // ─── Exception ───────────────────────────────────────────────────────

    /**
     * Custom exception for OrderPricingService errors
     */
    public class OrderPricingServiceException extends Exception {}
}