package com.mercadeonica.modelo;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;

public class Pedido {

    private int    orderId;
    private int    customerId;
    private int    sellerId;
    private Date   fecha;
    private long   ccNumber;
    private String estado;
    private double total;
    private List<DetallePedido> detalles;

    private String customerName;
    private String customerEmail;
    private String sellerName;

    // 🔥 NUEVO CAMPO: PAÍS DEL CLIENTE
    private String clientePais;

    public Pedido() {
        this.detalles = new ArrayList<>();
        this.estado   = "PENDIENTE";
    }

    public Pedido(int customerId, int sellerId, long ccNumber, Date fecha) {
        this.customerId = customerId;
        this.sellerId   = sellerId;
        this.ccNumber   = ccNumber;
        this.fecha      = fecha;
        this.estado     = "PENDIENTE";
        this.total      = 0.0;
        this.detalles   = new ArrayList<>();
    }

    public int    getOrderId()    { return orderId; }
    public int    getCustomerId() { return customerId; }
    public int    getSellerId()   { return sellerId; }
    public Date   getFecha()      { return fecha; }
    public long   getCcNumber()   { return ccNumber; }
    public String getEstado()     { return estado; }
    public double getTotal()      { return total; }
    public List<DetallePedido> getDetalles() { return detalles; }
    public String getCustomerName()  { return customerName; }
    public String getCustomerEmail() { return customerEmail; }
    public String getSellerName()    { return sellerName; }
    
    // 🔥 NUEVO GETTER
    public String getClientePais()   { return clientePais; }

    public void setOrderId(int orderId)      { this.orderId = orderId; }
    public void setCustomerId(int c)         { this.customerId = c; }
    public void setSellerId(int s)           { this.sellerId = s; }
    public void setFecha(Date fecha)         { this.fecha = fecha; }
    public void setCcNumber(long cc)         { this.ccNumber = cc; }
    public void setEstado(String estado)     { this.estado = estado; }
    public void setTotal(double total)       { this.total = total; }
    public void setCustomerName(String customerName)   { this.customerName = customerName; }
    public void setCustomerEmail(String customerEmail) { this.customerEmail = customerEmail; }
    public void setSellerName(String sellerName)       { this.sellerName = sellerName; }
    
    // 🔥 NUEVO SETTER
    public void setClientePais(String clientePais)     { this.clientePais = clientePais; }

    public void agregarDetalle(Producto producto, int cantidad) {
        DetallePedido d = new DetallePedido(producto, cantidad);
        detalles.add(d);
        this.total += d.getSubtotal();
    }

    public double calcularTotal() {
        double suma = 0;
        for (DetallePedido d : detalles) suma += d.getSubtotal();
        this.total = suma;
        return suma;
    }

    @Override
    public String toString() {
        return "Pedido{" +
                "orderId=" + orderId +
                ", customerId=" + customerId +
                ", customerName='" + customerName + '\'' +
                ", clientePais='" + clientePais + '\'' +
                ", total=" + total +
                ", items=" + detalles.size() +
                '}';
    }
}