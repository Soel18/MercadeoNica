package com.mercadeonica.modelo;

public class Vendedor {

    private int     sellerId;
    private String  nombre;
    private String  email;
    private String  telefono;    // 🔥 NUEVO
    private String  passwordHash;
    private String  rol;
    private boolean activo;

    public Vendedor() {
    }

    public Vendedor(int sellerId, String nombre, String email,
                    String passwordHash, String rol, boolean activo) {
        this.sellerId     = sellerId;
        this.nombre       = nombre;
        this.email        = email;
        this.passwordHash = passwordHash;
        this.rol          = rol;
        this.activo       = activo;
    }

    public int     getSellerId()     { return sellerId; }
    public String  getNombre()       { return nombre; }
    public String  getEmail()        { return email; }
    public String  getTelefono()     { return telefono; }   // 🔥 NUEVO
    public String  getPasswordHash() { return passwordHash; }
    public String  getRol()          { return rol; }
    public boolean isActivo()        { return activo; }

    public void setSellerId(int sellerId)           { this.sellerId = sellerId; }
    public void setNombre(String nombre)            { this.nombre = nombre; }
    public void setEmail(String email)              { this.email = email; }
    public void setTelefono(String telefono)        { this.telefono = telefono; }   // 🔥 NUEVO
    public void setPasswordHash(String passwordHash){ this.passwordHash = passwordHash; }
    public void setRol(String rol)                  { this.rol = rol; }
    public void setActivo(boolean activo)           { this.activo = activo; }

    public boolean esAdmin() {
        return "ADMIN".equalsIgnoreCase(this.rol);
    }

    @Override
    public String toString() {
        return "Vendedor{" +
                "sellerId=" + sellerId +
                ", nombre='" + nombre + '\'' +
                ", email='" + email + '\'' +
                ", telefono='" + telefono + '\'' +
                ", rol='" + rol + '\'' +
                ", activo=" + activo +
                '}';
    }
}