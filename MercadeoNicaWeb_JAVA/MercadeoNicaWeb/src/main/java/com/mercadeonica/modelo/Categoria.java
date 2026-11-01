package com.mercadeonica.modelo;

/**
 * Clase POO que representa una Categoría de productos.
 * Mapea la tabla 'ProductCategories' de la BD OSF.
 */
public class Categoria {

    // ---------- Atributos ----------
    private int     categoryId;
    private String  nombre;
    private String  descripcion;

    // ---------- Constructor vacío ----------
    public Categoria() {
    }

    // ---------- Constructor completo ----------
    public Categoria(int categoryId, String nombre, String descripcion) {
        this.categoryId  = categoryId;
        this.nombre      = nombre;
        this.descripcion = descripcion;
    }

    // ---------- Getters ----------
    public int    getCategoryId()  { return categoryId; }
    public String getNombre()      { return nombre; }
    public String getDescripcion() { return descripcion; }

    // ---------- Setters ----------
    public void setCategoryId(int categoryId)       { this.categoryId = categoryId; }
    public void setNombre(String nombre)            { this.nombre = nombre; }
    public void setDescripcion(String descripcion)  { this.descripcion = descripcion; }

    @Override
    public String toString() {
        return "Categoria{" +
                "categoryId=" + categoryId +
                ", nombre='" + nombre + '\'' +
                '}';
    }
}