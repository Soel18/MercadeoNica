package com.mercadeonica.modelo;

import java.util.ArrayList;
import java.util.List;

public class Carrito {

    private NodoCarrito cabeza;
    private NodoCarrito cola;
    private int         tamaño;
    private Cliente     cliente;

    public Carrito() {
        this.cabeza  = null;
        this.cola    = null;
        this.tamaño  = 0;
        this.cliente = null;
    }

    public void agregarProducto(Producto producto, int cantidad) {
        if (producto == null || cantidad <= 0) {
            return;
        }

        // 🔥 VALIDAR STOCK ANTES DE AGREGAR
        int yaEnCarrito = cantidadDe(producto.getProductId());
        int disponibleReal = producto.getCantidadDisponible();
        
        if (yaEnCarrito + cantidad > disponibleReal) {
            System.err.println("⚠️ Stock insuficiente para '" + producto.getNombre() + 
                               "'. Disponible: " + disponibleReal + ", intentas agregar: " + (yaEnCarrito + cantidad));
            return; // No agrega nada
        }

        NodoCarrito actual = cabeza;
        while (actual != null) {
            if (actual.producto.getProductId() == producto.getProductId()) {
                actual.cantidad += cantidad;
                System.out.println("🔵 Cantidad actualizada: " + producto.getNombre() + " → " + actual.cantidad);
                return;
            }
            actual = actual.siguiente;
        }

        NodoCarrito nuevo = new NodoCarrito(producto, cantidad);

        if (cabeza == null) {
            cabeza = nuevo;
            cola   = nuevo;
        } else {
            nuevo.anterior = cola;
            cola.siguiente = nuevo;
            cola           = nuevo;
        }
        tamaño++;
        System.out.println("🔵 Producto agregado al carrito: " + producto.getNombre() + " x" + cantidad);
    }

    public boolean eliminarProducto(int productId) {
        NodoCarrito actual = cabeza;

        while (actual != null) {
            if (actual.producto.getProductId() == productId) {
                if (actual.anterior != null) {
                    actual.anterior.siguiente = actual.siguiente;
                } else {
                    cabeza = actual.siguiente;
                }

                if (actual.siguiente != null) {
                    actual.siguiente.anterior = actual.anterior;
                } else {
                    cola = actual.anterior;
                }

                tamaño--;
                System.out.println("🔴 Producto eliminado del carrito: " + actual.producto.getNombre());
                return true;
            }
            actual = actual.siguiente;
        }
        return false;
    }

    public void vaciar() {
        cabeza = null;
        cola   = null;
        tamaño = 0;
        System.out.println("🗑️ Carrito vaciado (cliente conservado: " +
                           (cliente != null ? cliente.getNombre() : "ninguno") + ")");
    }

    public void vaciarTodo() {
        vaciar();
        cliente = null;
    }

    public double calcularTotal() {
        double total = 0;
        NodoCarrito actual = cabeza;
        while (actual != null) {
            total += actual.getSubtotal();
            actual = actual.siguiente;
        }
        return total;
    }

    public double calcularDescuento() {
        if (cliente == null) return 0;
        return calcularTotal() * (cliente.getDescuento() / 100.0);
    }

    public double calcularTotalConDescuento() {
        return calcularTotal() - calcularDescuento();
    }

    public List<NodoCarrito> listar() {
        List<NodoCarrito> lista = new ArrayList<>();
        NodoCarrito actual = cabeza;
        while (actual != null) {
            lista.add(actual);
            actual = actual.siguiente;
        }
        return lista;
    }

    public int cantidadDe(int productId) {
        NodoCarrito actual = cabeza;
        while (actual != null) {
            if (actual.producto.getProductId() == productId) {
                return actual.cantidad;
            }
            actual = actual.siguiente;
        }
        return 0;
    }

    public void mostrar() {
        System.out.println("=== Carrito de compras ===");
        NodoCarrito actual = cabeza;
        while (actual != null) {
            System.out.printf("- %s x%d = $%.2f%n",
                    actual.producto.getNombre(),
                    actual.cantidad,
                    actual.getSubtotal());
            actual = actual.siguiente;
        }
        System.out.printf("Subtotal: $%.2f%n", calcularTotal());
        if (cliente != null) {
            System.out.printf("Descuento (%.0f%%): -$%.2f%n", cliente.getDescuento(), calcularDescuento());
            System.out.printf("TOTAL: $%.2f%n", calcularTotalConDescuento());
        } else {
            System.out.printf("TOTAL: $%.2f (sin cliente asignado)%n", calcularTotal());
        }
    }

    public void enqueue(Producto producto, int cantidad) {
        agregarProducto(producto, cantidad);
    }

    public NodoCarrito dequeue() {
        if (cabeza == null) return null;

        NodoCarrito primero = cabeza;
        cabeza = cabeza.siguiente;

        if (cabeza != null) {
            cabeza.anterior = null;
        } else {
            cola = null;
        }

        tamaño--;
        return primero;
    }

    public NodoCarrito peek() {
        return cabeza;
    }

    public int     getTamaño()  { return tamaño; }
    public boolean estaVacio()  { return cabeza == null; }

    public Cliente getCliente() { return cliente; }

    public void setCliente(Cliente cliente) {
        this.cliente = cliente;
        if (cliente != null) {
            System.out.println("👤 Cliente asignado al carrito: " + cliente.getNombre() +
                               " (" + cliente.getCategoriaNombre() + " - " + cliente.getDescuento() + "%)");
        }
    }

    public boolean tieneCliente() {
        return cliente != null;
    }

    public Pedido convertirAPedido(int customerId, int sellerId, long ccNumber) {
        Pedido pedido = new Pedido(customerId, sellerId, ccNumber, new java.util.Date());

        NodoCarrito actual = cabeza;
        while (actual != null) {
            pedido.agregarDetalle(actual.producto, actual.cantidad);
            actual = actual.siguiente;
        }
        return pedido;
    }
}