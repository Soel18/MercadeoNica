package com.mercadeonica.modelo;

public class Cliente {

    private int     customerId;
    private String  nombre;
    private String  email;
    private String  ciudad;
    private String  estado;
    private int     zip;
    private String  telefono;        
    private String  passwordHash;
    private boolean active;
    private int     categoryId;
    private String  categoriaNombre;
    private double  descuento;
    private int     totalPedidos;
    private double  totalComprado;
    
    // 🔥 NUEVO ATRIBUTO
    private boolean debeCambiarPassword; 

    public Cliente() {
    }

    public Cliente(int customerId, String nombre, String email,
                   String ciudad, String estado, int zip,
                   String passwordHash, boolean active) {
        this.customerId   = customerId;
        this.nombre       = nombre;
        this.email        = email;
        this.ciudad       = ciudad;
        this.estado       = estado;
        this.zip          = zip;
        this.passwordHash = passwordHash;
        this.active       = active;
    }

    public Cliente(int customerId, String nombre, String email,
                   String ciudad, String estado, int zip) {
        this(customerId, nombre, email, ciudad, estado, zip, null, true);
    }

    // ---------- GETTERS ----------
    public int     getCustomerId()    { return customerId; }
    public String  getNombre()        { return nombre; }
    public String  getEmail()         { return email; }
    public String  getCiudad()        { return ciudad; }
    public String  getEstado()        { return estado; }
    public int     getZip()           { return zip; }
    public String  getTelefono()      { return telefono; }        
    public String  getPasswordHash()  { return passwordHash; }
    public boolean isActive()         { return active; }
    public int     getCategoryId()    { return categoryId; }
    public String  getCategoriaNombre() { return categoriaNombre; }
    public double  getDescuento()     { return descuento; }
    public int     getTotalPedidos()  { return totalPedidos; }
    public double  getTotalComprado() { return totalComprado; }
    
    // 🔥 NUEVO GETTER
    public boolean isDebeCambiarPassword() { return debeCambiarPassword; }

    // ---------- SETTERS ----------
    public void setCustomerId(int customerId)         { this.customerId = customerId; }
    public void setNombre(String nombre)              { this.nombre = nombre; }
    public void setEmail(String email)                { this.email = email; }
    public void setCiudad(String ciudad)              { this.ciudad = ciudad; }
    public void setEstado(String estado)              { this.estado = estado; }
    public void setZip(int zip)                       { this.zip = zip; }
    public void setTelefono(String telefono)          { this.telefono = telefono; }   
    public void setPasswordHash(String passwordHash)  { this.passwordHash = passwordHash; }
    public void setActive(boolean active)             { this.active = active; }
    public void setCategoryId(int categoryId)         { this.categoryId = categoryId; }
    public void setCategoriaNombre(String c)          { this.categoriaNombre = c; }
    public void setDescuento(double descuento)        { this.descuento = descuento; }
    public void setTotalPedidos(int totalPedidos)     { this.totalPedidos = totalPedidos; }
    public void setTotalComprado(double totalComprado){ this.totalComprado = totalComprado; }
    
    // 🔥 NUEVO SETTER
    public void setDebeCambiarPassword(boolean debeCambiarPassword) { this.debeCambiarPassword = debeCambiarPassword; }

    // ---------- MÉTODOS DE NEGOCIO ----------
    public double aplicarDescuento(double montoOriginal) {
        return montoOriginal * (1 - this.descuento / 100.0);
    }

    public double calcularAhorro(double montoOriginal) {
        return montoOriginal * (this.descuento / 100.0);
    }

    public String getNombreCompleto() {
        return nombre;
    }

    public String getCategoriaSugerida() {
        if (totalComprado >= 5000)      return "Platino";
        else if (totalComprado >= 2000) return "Oro";
        else if (totalComprado >= 500)  return "Plata";
        else if (totalComprado >= 100)  return "Bronce";
        else                            return "Regular";
    }

    public boolean mereceUpgrade() {
        String actual = categoriaNombre != null ? categoriaNombre : "Regular";
        return !actual.equalsIgnoreCase(getCategoriaSugerida());
    }

    @Override
    public String toString() {
        return "Cliente{" +
                "customerId=" + customerId +
                ", nombre='" + nombre + '\'' +
                ", email='" + email + '\'' +
                ", telefono='" + telefono + '\'' +
                ", categoria='" + categoriaNombre + '\'' +
                ", descuento=" + descuento + "%" +
                ", totalPedidos=" + totalPedidos +
                ", totalComprado=$" + totalComprado +
                ", debeCambiarPassword=" + debeCambiarPassword +
                '}';
    }
}