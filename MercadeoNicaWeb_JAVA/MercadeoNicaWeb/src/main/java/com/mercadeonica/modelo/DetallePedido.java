package com.mercadeonica.modelo;

/**
 * Clase POO que representa un Detalle de Pedido.
 * Mapea la tabla 'order_details' de la BD OSF.
 */
public class DetallePedido {

    // ---------- Atributos ----------
    private int      detailId;
    private int      orderId;
    private Producto producto;
    private int      cantidad;
    private double   precioUnitario;

    // ---------- Constructor vacío ----------
    public DetallePedido() {
    }

    // ---------- Constructor desde Producto ----------
    public DetallePedido(Producto producto, int cantidad) {
        this.producto       = producto;
        this.cantidad       = cantidad;
        this.precioUnitario = producto.getPrecioUnitario();
    }

    // ---------- Getters ----------
    public int      getDetailId()       { return detailId; }
    public int      getOrderId()        { return orderId; }
    public Producto getProducto()       { return producto; }
    public int      getCantidad()       { return cantidad; }
    public double   getPrecioUnitario() { return precioUnitario; }

    // ---------- Setters ----------
    public void setDetailId(int detailId)      { this.detailId = detailId; }
    public void setOrderId(int orderId)        { this.orderId = orderId; }
    public void setProducto(Producto p)        { this.producto = p; }
    public void setCantidad(int cantidad)      { this.cantidad = cantidad; }
    public void setPrecioUnitario(double p)    { this.precioUnitario = p; }

    // ---------- Métodos de negocio ----------
    public double getSubtotal() {
        return this.cantidad * this.precioUnitario;
    }
}