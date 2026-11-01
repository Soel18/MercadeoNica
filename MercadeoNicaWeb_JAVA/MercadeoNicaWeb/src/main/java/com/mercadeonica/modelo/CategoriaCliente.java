package com.mercadeonica.modelo;

/**
 * Clase POO que representa una categoría de cliente.
 * Cada categoría tiene un porcentaje de descuento asociado.
 */
public class CategoriaCliente {

    private int     categoryId;
    private String  nombre;
    private double  descuento;
    private String  descripcion;

    public CategoriaCliente() {
    }

    public CategoriaCliente(int categoryId, String nombre, double descuento, String descripcion) {
        this.categoryId  = categoryId;
        this.nombre      = nombre;
        this.descuento   = descuento;
        this.descripcion = descripcion;
    }

    public int    getCategoryId()  { return categoryId; }
    public String getNombre()      { return nombre; }
    public double getDescuento()   { return descuento; }
    public String getDescripcion() { return descripcion; }

    public void setCategoryId(int categoryId)     { this.categoryId = categoryId; }
    public void setNombre(String nombre)          { this.nombre = nombre; }
    public void setDescuento(double descuento)    { this.descuento = descuento; }
    public void setDescripcion(String desc)       { this.descripcion = desc; }

    public String getEtiqueta() {
        return nombre + " (" + (int) descuento + "% desc.)";
    }

    @Override
    public String toString() {
        return "CategoriaCliente{" +
                "categoryId=" + categoryId +
                ", nombre='" + nombre + '\'' +
                ", descuento=" + descuento +
                '}';
    }
}
