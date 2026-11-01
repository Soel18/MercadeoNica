<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.mercadeonica.modelo.Pedido" %>
<%@ page import="com.mercadeonica.modelo.DetallePedido" %>
<%@ page import="com.mercadeonica.modelo.Cliente" %>
<%@ page import="com.mercadeonica.util.MonedaUtil" %>
<%@ page import="java.util.List" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.text.DecimalFormat" %>
<%
    Pedido pedido = (Pedido) request.getAttribute("pedido");
    List<DetallePedido> detalles = (List<DetallePedido>) request.getAttribute("detalles");
    Cliente cliente = (Cliente) request.getAttribute("cliente");

    if (pedido == null) {
        response.sendRedirect("PedidoServlet");
        return;
    }

    SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy HH:mm");
    DecimalFormat df = new DecimalFormat("#,##0.00");

    String clienteNombre = pedido.getCustomerName() != null ? pedido.getCustomerName() : "Cliente #" + pedido.getCustomerId();
    String clienteEmail  = pedido.getCustomerEmail() != null ? pedido.getCustomerEmail() : "N/A";
    String vendedorNombre = pedido.getSellerName() != null ? pedido.getSellerName() : "Venta Online";

    String metodoPagoMostrar = "Efectivo";
    if (pedido.getCcNumber() > 0) {
        String ccStr = String.valueOf(pedido.getCcNumber());
        String ultimos4 = ccStr.substring(Math.max(0, ccStr.length() - 4));
        metodoPagoMostrar = "Tarjeta **** " + ultimos4;
    }

    // 🔥 MONEDA SEGÚN EL PAÍS DEL CLIENTE
    String paisCliente   = "Nicaragua";
    String codigoMoneda  = "NIO";
    String simbolo       = "C$";

    if (cliente != null && cliente.getEstado() != null && !cliente.getEstado().isEmpty()) {
        paisCliente  = cliente.getEstado();
        codigoMoneda = MonedaUtil.getCodigo(paisCliente);
        simbolo      = MonedaUtil.getSimbolo(paisCliente);
    }

    double totalFinalUSD      = pedido.getTotal();
    double totalEnMonedaLocal = MonedaUtil.convertirAmonedaLocal(totalFinalUSD, paisCliente);
    double totalEnNIO         = MonedaUtil.convertirANIO(totalFinalUSD);
    boolean esNicaragua       = "NIO".equalsIgnoreCase(codigoMoneda);
%>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Factura #<%= pedido.getOrderId() %> - MercadeoNica</title>
    <style>
        body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; color: #333; background: #f4f6f8; margin: 0; padding: 20px; }
        .factura-box { max-width: 800px; margin: 0 auto; background: white; padding: 40px; box-shadow: 0 0 20px rgba(0,0,0,0.1); border-radius: 8px; }

        .header { display: flex; justify-content: space-between; align-items: flex-start; border-bottom: 3px solid #2980b9; padding-bottom: 20px; margin-bottom: 30px; }
        .logo h1 { margin: 0; color: #2c3e50; font-size: 2.2em; }
        .logo p { margin: 5px 0 0 0; color: #7f8c8d; font-size: 0.9em; }
        .info-factura { text-align: right; }
        .info-factura h2 { margin: 0; color: #e74c3c; font-size: 1.8em; text-transform: uppercase; }
        .info-factura p { margin: 5px 0; font-size: 0.95em; }

        .detalles { display: flex; justify-content: space-between; margin-bottom: 30px; background: #f8f9fa; padding: 20px; border-radius: 6px; border-left: 4px solid #2980b9; }
        .detalles div { flex: 1; }
        .detalles h3 { margin: 0 0 10px 0; color: #2c3e50; font-size: 1em; text-transform: uppercase; letter-spacing: 1px; }
        .detalles p { margin: 4px 0; font-size: 0.9em; color: #555; }

        table { width: 100%; border-collapse: collapse; margin-bottom: 30px; }
        th { background: #34495e; color: white; padding: 12px; text-align: left; font-size: 0.9em; text-transform: uppercase; }
        td { padding: 12px; border-bottom: 1px solid #ecf0f1; font-size: 0.95em; }
        .text-right { text-align: right; }

        .totales { width: 50%; float: right; }
        .totales table { margin: 0; }
        .totales td { border: none; padding: 8px 12px; }
        .totales .total-final { background: #27ae60; color: white; font-size: 1.2em; font-weight: bold; border-radius: 4px; }
        .totales .total-final small { display: block; margin-top: 4px; font-size: 0.7em; color: #d5f5e3; }

        .footer { clear: both; text-align: center; margin-top: 50px; padding-top: 20px; border-top: 1px solid #ecf0f1; color: #7f8c8d; font-size: 0.85em; }
        .no-print { text-align: center; margin-bottom: 20px; }

        @media print {
            body { background: white; padding: 0; }
            .factura-box { box-shadow: none; padding: 0; max-width: 100%; margin: 0; }
            .no-print { display: none !important; }
            .header { border-bottom-color: #000; }
            .total-final { background: #000 !important; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
        }
    </style>
</head>
<body>

    <div class="no-print">
        <button onclick="window.print()" style="background: #27ae60; color: white; border: none; padding: 12px 25px; font-size: 1.1em; border-radius: 5px; cursor: pointer; font-weight: bold;">
            🖨️ Guardar Factura como PDF / Imprimir
        </button>
    </div>

    <div class="factura-box">
        <div class="header">
            <div class="logo">
                <h1>🛒 MercadeoNica</h1>
                <p>Tu tienda de confianza</p>
                <p>RUC: 123456789-0001</p>
            </div>
            <div class="info-factura">
                <h2>FACTURA</h2>
                <p><b>N° Pedido:</b> #<%= pedido.getOrderId() %></p>
                <p><b>Fecha:</b> <%= pedido.getFecha() != null ? sdf.format(pedido.getFecha()) : "-" %></p>
                <p><b>Estado:</b> <span style="color: #27ae60; font-weight: bold;"><%= pedido.getEstado() %></span></p>
            </div>
        </div>

        <div class="detalles">
            <div>
                <h3>Facturado a:</h3>
                <p><b><%= clienteNombre %></b></p>
                <p>📧 <%= clienteEmail %></p>
                <p>🌍 País: <b><%= paisCliente %></b></p>
            </div>
            <div>
                <h3>Vendedor:</h3>
                <p><b><%= vendedorNombre %></b></p>
                <p>Método de pago: <b><%= metodoPagoMostrar %></b></p>
                <p>Moneda: <b><%= codigoMoneda %></b></p>
            </div>
        </div>

        <table>
            <thead>
                <tr>
                    <th>#</th>
                    <th>Descripción del Producto</th>
                    <th class="text-right">Precio Unit.</th>
                    <th class="text-right">Cant.</th>
                    <th class="text-right">Subtotal</th>
                </tr>
            </thead>
            <tbody>
                <% int i = 1;
                   double subtotalGeneral = 0;
                   if (detalles != null) {
                       for (DetallePedido d : detalles) {
                           subtotalGeneral += d.getSubtotal();
                %>
                    <tr>
                        <td><%= i++ %></td>
                        <td><%= d.getProducto().getNombre() %></td>
                        <td class="text-right">$<%= df.format(d.getPrecioUnitario()) %></td>
                        <td class="text-right"><%= d.getCantidad() %></td>
                        <td class="text-right">$<%= df.format(d.getSubtotal()) %></td>
                    </tr>
                <%     }
                   }
                %>
            </tbody>
        </table>

        <div class="totales">
            <table>
                <tr>
                    <td>Subtotal (USD):</td>
                    <td class="text-right">$<%= df.format(subtotalGeneral) %></td>
                </tr>
                <%
                   double descuento = subtotalGeneral - totalFinalUSD;
                   if (descuento > 0.01) {
                %>
                <tr>
                    <td style="color: #e74c3c;">Descuento:</td>
                    <td class="text-right" style="color: #e74c3c;">-$<%= df.format(descuento) %></td>
                </tr>
                <% } %>
                <tr class="total-final">
                    <td>TOTAL A PAGAR:</td>
                    <td class="text-right">
                        $<%= df.format(totalFinalUSD) %>
                        <% if (esNicaragua) { %>
                            <small>(<%= simbolo %><%= df.format(totalEnNIO) %>)</small>
                        <% } else { %>
                            <small><%= simbolo %><%= df.format(totalEnMonedaLocal) %> (<%= codigoMoneda %>)</small>
                            <small>Equivalente: C$<%= df.format(totalEnNIO) %></small>
                        <% } %>
                    </td>
                </tr>
            </table>
        </div>
        <div style="clear: both;"></div>

        <div class="footer">
            <p>¡Gracias por tu compra en MercadeoNica!</p>
            <p>Este documento es una representación impresa de tu factura electrónica.</p>
            <p>Si tienes dudas, contáctanos al <b>+505 8574-9825</b> o a soporte@mercadeonica.com</p>
        </div>
    </div>
</body>
</html>