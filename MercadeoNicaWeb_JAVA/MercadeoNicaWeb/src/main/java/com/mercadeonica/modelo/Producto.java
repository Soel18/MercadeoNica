package com.mercadeonica.modelo;

/**
 * Clase POO que representa un Producto.
 * Mapea la tabla 'products' de la BD OSF.
 */
public class Producto {

    // ---------- Atributos ----------
    private int     productId;
    private String  nombre;
    private int     cantidadDisponible;
    private double  precioUnitario;
    private int     categoriaId;
    private String  categoriaNombre;   // Para mostrar en la vista

    // ---------- Constructor vacío ----------
    public Producto() {
    }

    // ---------- Constructor completo ----------
    public Producto(int productId, String nombre, int cantidadDisponible,
                    double precioUnitario, int categoriaId) {
        this.productId          = productId;
        this.nombre             = nombre;
        this.cantidadDisponible = cantidadDisponible;
        this.precioUnitario     = precioUnitario;
        this.categoriaId        = categoriaId;
    }

    // ---------- Getters ----------
    public int     getProductId()          { return productId; }
    public String  getNombre()             { return nombre; }
    public int     getCantidadDisponible() { return cantidadDisponible; }
    public double  getPrecioUnitario()     { return precioUnitario; }
    public int     getCategoriaId()        { return categoriaId; }
    public String  getCategoriaNombre()    { return categoriaNombre; }

    // ---------- Setters ----------
    public void setProductId(int productId)               { this.productId = productId; }
    public void setNombre(String nombre)                  { this.nombre = nombre; }
    public void setCantidadDisponible(int cantidad)       { this.cantidadDisponible = cantidad; }
    public void setPrecioUnitario(double precio)          { this.precioUnitario = precio; }
    public void setCategoriaId(int categoriaId)           { this.categoriaId = categoriaId; }
    public void setCategoriaNombre(String nombre)         { this.categoriaNombre = nombre; }

    // ---------- Métodos de negocio ----------
    public boolean hayStock(int cantidad) {
        return this.cantidadDisponible >= cantidad;
    }

    public double calcularSubtotal(int cantidad) {
        return this.precioUnitario * cantidad;
    }

    @Override
    public String toString() {
        return "Producto{" +
                "productId=" + productId +
                ", nombre='" + nombre + '\'' +
                ", cantidadDisponible=" + cantidadDisponible +
                ", precioUnitario=" + precioUnitario +
                ", categoriaId=" + categoriaId +
                '}';
    }
}