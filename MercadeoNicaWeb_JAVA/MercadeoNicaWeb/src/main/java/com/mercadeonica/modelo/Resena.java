package com.mercadeonica.modelo;

import java.util.Date;

/**
 * Representa una reseña de un producto hecha por un cliente.
 * Mapea la tabla 'reviews' de la BD OSF.
 */
public class Resena {

    private int    reviewId;
    private int    productId;
    private String productName;    // para mostrar
    private int    customerId;     // NUEVO: cliente que hizo la reseña
    private String reviewerEmail;  // ya existe en la BD
    private int    estrellas;      // 1-5
    private String comentario;
    private Date   fecha;          // NUEVO: fecha de la reseña (si se agrega)

    public Resena() {
    }

    public Resena(int productId, String reviewerEmail, int estrellas, String comentario) {
        this.productId     = productId;
        this.reviewerEmail = reviewerEmail;
        this.estrellas     = estrellas;
        this.comentario    = comentario;
    }

    // ---------- Getters ----------
    public int    getReviewId()       { return reviewId; }
    public int    getProductId()      { return productId; }
    public String getProductName()    { return productName; }
    public int    getCustomerId()     { return customerId; }
    public String getReviewerEmail()  { return reviewerEmail; }
    public int    getEstrellas()      { return estrellas; }
    public String getComentario()     { return comentario; }
    public Date   getFecha()          { return fecha; }

    // ---------- Setters ----------
    public void setReviewId(int reviewId)            { this.reviewId = reviewId; }
    public void setProductId(int productId)          { this.productId = productId; }
    public void setProductName(String productName)   { this.productName = productName; }
    public void setCustomerId(int customerId)        { this.customerId = customerId; }
    public void setReviewerEmail(String email)       { this.reviewerEmail = email; }
    public void setEstrellas(int estrellas)          { this.estrellas = estrellas; }
    public void setComentario(String comentario)     { this.comentario = comentario; }
    public void setFecha(Date fecha)                 { this.fecha = fecha; }

    // ---------- Utilidades ----------
    public String getEstrellasVisual() {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < estrellas; i++) sb.append("⭐");
        return sb.toString();
    }

    public String getEstrellasVaciasVisual() {
        StringBuilder sb = new StringBuilder();
        for (int i = estrellas; i < 5; i++) sb.append("☆");
        return sb.toString();
    }
}