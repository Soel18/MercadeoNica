package com.mercadeonica.controlador;

import com.mercadeonica.dao.PedidoDAO;
import com.mercadeonica.dao.TarjetaDAO;
import com.mercadeonica.modelo.Carrito;
import com.mercadeonica.modelo.Cliente;
import com.mercadeonica.modelo.Pedido;
import com.mercadeonica.modelo.Tarjeta;
import com.mercadeonica.util.MonedaUtil;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.text.SimpleDateFormat;

@WebServlet(name = "ClientePedidoServlet", urlPatterns = {"/ClientePedidoServlet"})
public class ClientePedidoServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        System.out.println("========== ClientePedidoServlet.doPost ==========");

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("cliente") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        Cliente cliente = (Cliente) session.getAttribute("cliente");
        Carrito carrito = (Carrito) session.getAttribute("carritoCliente");

        if (carrito == null || carrito.estaVacio()) {
            session.setAttribute("error", "El carrito está vacío.");
            response.sendRedirect("ClienteCarritoServlet");
            return;
        }

        try {
            String metodoPago = request.getParameter("metodoPago");
            String ccNumberStr = null;

            // 1. Lógica para TARJETA
            if ("tarjeta".equals(metodoPago)) {
                String modoPago = request.getParameter("modoPago");
                if ("guardada".equals(modoPago)) {
                    ccNumberStr = request.getParameter("ccSeleccionada");
                    if (ccNumberStr == null || ccNumberStr.isBlank()) {
                        session.setAttribute("error", "⚠️ Debes seleccionar una tarjeta guardada.");
                        response.sendRedirect("cliente-confirmar-pedido.jsp");
                        return;
                    }
                } else {
                    ccNumberStr = request.getParameter("ccNumber");
                    if (ccNumberStr == null || ccNumberStr.isBlank()) {
                        session.setAttribute("error", "⚠️ Debes ingresar el número de tarjeta.");
                        response.sendRedirect("cliente-confirmar-pedido.jsp");
                        return;
                    }

                    String guardar = request.getParameter("guardarTarjeta");
                    if ("si".equals(guardar)) {
                        try {
                            long num = Long.parseLong(ccNumberStr);
                            String tipo = request.getParameter("ccTipo");
                            int mes  = Integer.parseInt(request.getParameter("ccMes"));
                            int anio = Integer.parseInt(request.getParameter("ccAnio"));

                            if (tipo != null && !tipo.isBlank()) {
                                TarjetaDAO tDao = new TarjetaDAO();
                                Tarjeta t = new Tarjeta(cliente.getCustomerId(), num, tipo, mes, anio);
                                String errT = tDao.agregar(t);
                                if (errT == null) {
                                    System.out.println("✅ Tarjeta guardada en el perfil del cliente.");
                                }
                            }
                        } catch (Exception eSave) {
                            System.err.println("⚠️ Error al guardar tarjeta (ignorado): " + eSave.getMessage());
                        }
                    }
                }
            }

            long ccNumber = 0;
            if ("tarjeta".equals(metodoPago)) {
                ccNumber = Long.parseLong(ccNumberStr);
            }

            String fechaStr = request.getParameter("orderDate");
            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
            sdf.setLenient(false);
            java.util.Date fecha = sdf.parse(fechaStr);

            Pedido pedido = carrito.convertirAPedido(
                    cliente.getCustomerId(),
                    0, 
                    ccNumber
            );
            pedido.setFecha(fecha);
            pedido.setEstado("PENDIENTE");

            double totalOriginal = pedido.calcularTotal();
            double descuento = cliente.getDescuento();
            double totalFinalUSD = totalOriginal * (1 - descuento / 100.0);

            PedidoDAO dao = new PedidoDAO();
            boolean ok = dao.registrarConDescuento(pedido, descuento);

            if (ok) {
                session.removeAttribute("carritoCliente");
                double ahorro = totalOriginal - totalFinalUSD;

                // 🔥 DETECTAR MONEDA DEL CLIENTE SEGÚN SU PAÍS
                String paisCliente = cliente.getEstado() != null ? cliente.getEstado() : "Nicaragua";
                String codigoMoneda = MonedaUtil.getCodigo(paisCliente);
                double tasaCambio = MonedaUtil.getTasa(paisCliente);
                String simbolo = MonedaUtil.getSimbolo(paisCliente);
                double totalEnMonedaLocal = MonedaUtil.convertirAmonedaLocal(totalFinalUSD, paisCliente);
                double totalEnNIO = MonedaUtil.convertirANIO(totalFinalUSD);

                // 🔥 MENSAJE CON LA MONEDA LOCAL + CÓRDOBAS
                String mensaje;
                if ("NIO".equals(codigoMoneda)) {
                    mensaje = "¡Pedido registrado! Total: C$ " + String.format("%.2f", totalEnNIO) +
                              " | Equivalente en USD: $" + String.format("%.2f", totalFinalUSD);
                } else {
                    mensaje = "¡Pedido registrado! Total: " + simbolo + String.format("%.2f", totalEnMonedaLocal) +
                              " (" + codigoMoneda + ")" +
                              " | Equivalente en C$: " + String.format("%.2f", totalEnNIO);
                }

                if (descuento > 0) {
                    mensaje += " | Descuento " + (int)descuento + "%: -$" + String.format("%.2f", ahorro);
                }

                session.setAttribute("mensaje", mensaje);
                response.sendRedirect("ClienteMisPedidosServlet");
            } else {
                session.setAttribute("error", "❌ Error al registrar el pedido. Revisa el stock o intenta de nuevo.");
                response.sendRedirect("ClienteCarritoServlet");
            }

        } catch (NumberFormatException nfe) {
            session.setAttribute("error", "⚠️ Número de tarjeta inválido.");
            response.sendRedirect("cliente-confirmar-pedido.jsp");
        } catch (Exception e) {
            System.err.println("❌ Error: " + e.getMessage());
            e.printStackTrace();
            session.setAttribute("error", "Error: " + e.getMessage());
            response.sendRedirect("ClienteCarritoServlet");
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect("ClienteCarritoServlet");
    }
}