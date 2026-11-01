package com.mercadeonica.util;

import java.util.HashMap;
import java.util.Map;

public class MonedaUtil {

    public static final double TASA_CAMBIO_NIO = 36.50;

    private static final Map<String, Object[]> PAIS_MONEDA = new HashMap<>();
    static {
        // América
        PAIS_MONEDA.put("Nicaragua", new Object[]{"NIO", 36.50, "C$"});
        PAIS_MONEDA.put("Estados Unidos", new Object[]{"USD", 1.00, "$"});
        PAIS_MONEDA.put("México", new Object[]{"MXN", 17.00, "MX$"});
        PAIS_MONEDA.put("Costa Rica", new Object[]{"CRC", 520.00, "₡"});
        PAIS_MONEDA.put("Honduras", new Object[]{"HNL", 24.70, "L"});
        PAIS_MONEDA.put("El Salvador", new Object[]{"USD", 1.00, "$"});
        PAIS_MONEDA.put("Guatemala", new Object[]{"GTQ", 7.80, "Q"});
        PAIS_MONEDA.put("Panamá", new Object[]{"PAB", 1.00, "B/."});
        PAIS_MONEDA.put("Colombia", new Object[]{"COP", 3900.00, "COL$"});
        PAIS_MONEDA.put("Venezuela", new Object[]{"VES", 36.00, "Bs."});
        PAIS_MONEDA.put("Ecuador", new Object[]{"USD", 1.00, "$"});
        PAIS_MONEDA.put("Perú", new Object[]{"PEN", 3.70, "S/"});
        PAIS_MONEDA.put("Bolivia", new Object[]{"BOB", 6.90, "Bs"});
        PAIS_MONEDA.put("Chile", new Object[]{"CLP", 950.00, "CLP$"});
        PAIS_MONEDA.put("Argentina", new Object[]{"ARS", 1000.00, "AR$"});
        PAIS_MONEDA.put("Brasil", new Object[]{"BRL", 5.00, "R$"});
        PAIS_MONEDA.put("Uruguay", new Object[]{"UYU", 40.00, "$U"});
        PAIS_MONEDA.put("Paraguay", new Object[]{"PYG", 7300.00, "₲"});
        PAIS_MONEDA.put("Cuba", new Object[]{"CUP", 24.00, "₱"});
        PAIS_MONEDA.put("República Dominicana", new Object[]{"DOP", 58.00, "RD$"});
        PAIS_MONEDA.put("Puerto Rico", new Object[]{"USD", 1.00, "$"});
        PAIS_MONEDA.put("Canadá", new Object[]{"CAD", 1.35, "CA$"});
        // Europa
        PAIS_MONEDA.put("España", new Object[]{"EUR", 0.92, "€"});
        PAIS_MONEDA.put("Francia", new Object[]{"EUR", 0.92, "€"});
        PAIS_MONEDA.put("Alemania", new Object[]{"EUR", 0.92, "€"});
        PAIS_MONEDA.put("Italia", new Object[]{"EUR", 0.92, "€"});
        PAIS_MONEDA.put("Portugal", new Object[]{"EUR", 0.92, "€"});
        PAIS_MONEDA.put("Países Bajos", new Object[]{"EUR", 0.92, "€"});
        PAIS_MONEDA.put("Bélgica", new Object[]{"EUR", 0.92, "€"});
        PAIS_MONEDA.put("Austria", new Object[]{"EUR", 0.92, "€"});
        PAIS_MONEDA.put("Grecia", new Object[]{"EUR", 0.92, "€"});
        PAIS_MONEDA.put("Irlanda", new Object[]{"EUR", 0.92, "€"});
        PAIS_MONEDA.put("Reino Unido", new Object[]{"GBP", 0.79, "£"});
        PAIS_MONEDA.put("Suiza", new Object[]{"CHF", 0.88, "CHF"});
        PAIS_MONEDA.put("Suecia", new Object[]{"SEK", 10.50, "kr"});
        PAIS_MONEDA.put("Noruega", new Object[]{"NOK", 10.60, "kr"});
        PAIS_MONEDA.put("Dinamarca", new Object[]{"DKK", 6.85, "kr"});
        PAIS_MONEDA.put("Rusia", new Object[]{"RUB", 92.00, "₽"});
        PAIS_MONEDA.put("Ucrania", new Object[]{"UAH", 39.00, "₴"});
        PAIS_MONEDA.put("Polonia", new Object[]{"PLN", 4.00, "zł"});
        // Asia
        PAIS_MONEDA.put("China", new Object[]{"CNY", 7.20, "¥"});
        PAIS_MONEDA.put("Japón", new Object[]{"JPY", 150.00, "¥"});
        PAIS_MONEDA.put("Corea del Sur", new Object[]{"KRW", 1330.00, "₩"});
        PAIS_MONEDA.put("India", new Object[]{"INR", 83.00, "₹"});
        PAIS_MONEDA.put("Indonesia", new Object[]{"IDR", 15600.00, "Rp"});
        PAIS_MONEDA.put("Filipinas", new Object[]{"PHP", 56.00, "₱"});
        PAIS_MONEDA.put("Tailandia", new Object[]{"THB", 36.00, "฿"});
        PAIS_MONEDA.put("Vietnam", new Object[]{"VND", 24500.00, "₫"});
        PAIS_MONEDA.put("Malasia", new Object[]{"MYR", 4.70, "RM"});
        PAIS_MONEDA.put("Singapur", new Object[]{"SGD", 1.34, "S$"});
        // África
        PAIS_MONEDA.put("Egipto", new Object[]{"EGP", 47.00, "E£"});
        PAIS_MONEDA.put("Sudáfrica", new Object[]{"ZAR", 18.50, "R"});
        PAIS_MONEDA.put("Nigeria", new Object[]{"NGN", 1400.00, "₦"});
        PAIS_MONEDA.put("Kenia", new Object[]{"KES", 130.00, "KSh"});
        PAIS_MONEDA.put("Marruecos", new Object[]{"MAD", 10.00, "DH"});
        PAIS_MONEDA.put("Argelia", new Object[]{"DZD", 135.00, "DA"});
        // Oceanía
        PAIS_MONEDA.put("Australia", new Object[]{"AUD", 1.52, "A$"});
        PAIS_MONEDA.put("Nueva Zelanda", new Object[]{"NZD", 1.65, "NZ$"});
    }

    public static Object[] getMonedaPorPais(String pais) {
        if (pais == null) pais = "Nicaragua";
        Object[] info = PAIS_MONEDA.get(pais);
        if (info == null) return new Object[]{"USD", 1.00, "$"};
        return info;
    }

    public static String getSimbolo(String pais)   { return (String) getMonedaPorPais(pais)[2]; }
    public static String getCodigo(String pais)    { return (String) getMonedaPorPais(pais)[0]; }
    public static double getTasa(String pais)      { return (Double) getMonedaPorPais(pais)[1]; }

    public static double convertirAmonedaLocal(double montoUSD, String pais) {
        return montoUSD * getTasa(pais);
    }

    public static double convertirANIO(double montoUSD) {
        return montoUSD * TASA_CAMBIO_NIO;
    }
}