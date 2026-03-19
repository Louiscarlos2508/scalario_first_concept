export class StockAlertDto {
  catalogItemId: string;
  itemName: string;
  stockQuantity: number;
  minStockLevel: number;
  deficit: number; // minStockLevel - stockQuantity (> 0 = below threshold)
  tenantId: string;
}
