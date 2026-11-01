package com.mercadeonica.modelo;

/**
 * Representa una tarjeta de crédito de un cliente.
 * Mapea la tabla 'creditcards' de la BD OSF.
 */
public class Tarjeta {

    private int    customerId;
    private long   numero;          // Número completo (se muestra enmascarado)
    private String tipo;            // VISA, MC, AMEX, Discover
    private int    mesExpiracion;
    private int    anioExpiracion;

    public Tarjeta() {
    }

    public Tarjeta(int customerId, long numero, String tipo,
                   int mesExpiracion, int anioExpiracion) {
        this.customerId      = customerId;
        this.numero          = numero;
        this.tipo            = tipo;
        this.mesExpiracion   = mesExpiracion;
        this.anioExpiracion  = anioExpiracion;
    }

    // ---------- Getters ----------
    public int    getCustomerId()     { return customerId; }
    public long   getNumero()         { return numero; }
    public String getTipo()           { return tipo; }
    public int    getMesExpiracion()  { return mesExpiracion; }
    public int    getAnioExpiracion() { return anioExpiracion; }

    // ---------- Setters ----------
    public void setCustomerId(int customerId)          { this.customerId = customerId; }
    public void setNumero(long numero)                 { this.numero = numero; }
    public void setTipo(String tipo)                   { this.tipo = tipo; }
    public void setMesExpiracion(int mesExpiracion)    { this.mesExpiracion = mesExpiracion; }
    public void setAnioExpiracion(int anioExpiracion)  { this.anioExpiracion = anioExpiracion; }

    // ---------- Métodos de presentación ----------

    /** Devuelve el número enmascarado: **** **** **** 1234 */
    public String getNumeroEnmascarado() {
        String s = String.valueOf(numero);
        if (s.length() < 4) return "****";
        return "**** **** **** " + s.substring(s.length() - 4);
    }

    /** Devuelve solo los últimos 4 dígitos */
    public String getUltimos4() {
        String s = String.valueOf(numero);
        if (s.length() < 4) return s;
        return s.substring(s.length() - 4);
    }

    /** Formato MM/AA */
    public String getFechaExpiracion() {
        return String.format("%02d/%02d", mesExpiracion, anioExpiracion % 100);
    }

    /** ¿Está expirada? Compara con el año/mes actual */
    public boolean isExpirada() {
        java.time.LocalDate hoy = java.time.LocalDate.now();
        int anioActual = hoy.getYear();
        int mesActual  = hoy.getMonthValue();
        if (anioExpiracion < anioActual) return true;
        if (anioExpiracion == anioActual && mesExpiracion < mesActual) return true;
        return false;
    }

    @Override
    public String toString() {
        return "Tarjeta{" +
                "customerId=" + customerId +
                ", numero=" + getNumeroEnmascarado() +
                ", tipo='" + tipo + '\'' +
                ", expira=" + getFechaExpiracion() +
                '}';
    }
}