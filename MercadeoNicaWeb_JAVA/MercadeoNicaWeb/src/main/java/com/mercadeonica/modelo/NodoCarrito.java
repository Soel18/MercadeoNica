package com.mercadeonica.modelo;

/**
 * Nodo de la lista doblemente enlazada del carrito.
 * Cada nodo guarda un producto y su cantidad.
 */
public class NodoCarrito {

    // ---------- Atributos ----------
    Producto    producto;
    int         cantidad;
    NodoCarrito anterior;   // Puntero al nodo anterior
    NodoCarrito siguiente;  // Puntero al nodo siguiente

    // ---------- Constructor ----------
    public NodoCarrito(Producto producto, int cantidad) {
        this.producto  = producto;
        this.cantidad  = cantidad;
        this.anterior  = null;
        this.siguiente = null;
    }

    // ---------- Métodos ----------
    public double getSubtotal() {
        return producto.getPrecioUnitario() * cantidad;
    }

    public Producto getProducto() { return producto; }
    public int      getCantidad() { return cantidad; }
}