package com.mercadeonica.controlador;

import com.mercadeonica.dao.PedidoDAO;
import com.mercadeonica.dao.ClienteDAO;
import com.mercadeonica.modelo.Carrito;
import com.mercadeonica.modelo.Cliente;
import com.mercadeonica.modelo.DetallePedido;
import com.mercadeonica.modelo.Pedido;
import com.mercadeonica.modelo.Vendedor;
import com.mercadeonica.util.MonedaUtil;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.List;

@WebServlet(name = "PedidoServlet", urlPatterns = {"/PedidoServlet"})
public class PedidoServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        System.out.println("========== PedidoServlet.doGet ==========");

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("vendedor") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        PedidoDAO dao = new PedidoDAO();
        ClienteDAO clienteDAO = new ClienteDAO();
        String accion = request.getParameter("accion");

        if ("verDetalle".equals(accion)) {
            try {
                int orderId = Integer.parseInt(request.getParameter("id"));
                Pedido pedido = dao.buscarPorId(orderId);
                List<DetallePedido> detalles = dao.listarDetalles(orderId);

                request.setAttribute("pedido", pedido);
                request.setAttribute("detalles", detalles);
                request.getRequestDispatcher("pedido-detalle.jsp").forward(request, response);
                return;
            } catch (NumberFormatException e) {
                System.err.println("❌ ID inválido");
            }
        }

        else if ("verFactura".equals(accion)) {
            try {
                int orderId = Integer.parseInt(request.getParameter("id"));
                Pedido pedido = dao.buscarPorId(orderId);
                List<DetallePedido> detalles = dao.listarDetalles(orderId);

                // 🔥 NUEVO: cargar el cliente para que la factura sepa el país y la moneda
                Cliente clienteFactura = clienteDAO.buscarPorId(pedido.getCustomerId());
                request.setAttribute("cliente", clienteFactura);

                request.setAttribute("pedido", pedido);
                request.setAttribute("detalles", detalles);
                request.getRequestDispatcher("factura-pdf.jsp").forward(request, response);
                return;

            } catch (NumberFormatException e) {
                System.err.println("❌ ID inválido para factura");
            }
        }

        else if ("cambiarEstado".equals(accion)) {
            try {
                int orderId = Integer.parseInt(request.getParameter("id"));
                String nuevoEstado = request.getParameter("estado");
                System.out.println("📝 Cambiando pedido #" + orderId + " a: " + nuevoEstado);
                boolean ok = dao.cambiarEstado(orderId, nuevoEstado);

                request.setAttribute("mensaje", ok
                    ? "✅ Pedido #" + orderId + " marcado como " + nuevoEstado
                    : "❌ Error al cambiar estado");
            } catch (NumberFormatException e) {
                request.setAttribute("mensaje", "ID inválido");
            }
        }

        String filtro = request.getParameter("filtro");
        List<Pedido> pedidos = dao.listarPedidos(filtro);

        request.setAttribute("pedidos", pedidos);
        request.setAttribute("filtroActual", filtro);

        request.getRequestDispatcher("pedidos.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        System.out.println("========== PedidoServlet.doPost ==========");
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("vendedor") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        Vendedor vendedor = (Vendedor) session.getAttribute("vendedor");
        Carrito carrito = (Carrito) session.getAttribute("carrito");

        int sellerId = (vendedor != null) ? vendedor.getSellerId() : 1;
        System.out.println("   🧑‍💼 Vendedor que procesa: " + (vendedor != null ? vendedor.getNombre() + " (ID: " + sellerId + ")" : "Desconocido"));

        if (carrito == null || carrito.estaVacio()) {
            request.setAttribute("error", "El carrito está vacío.");
            request.getRequestDispatcher("carrito.jsp").forward(request, response);
            return;
        }

        Cliente cliente = carrito.getCliente();
        if (cliente == null) {
            request.setAttribute("error", "⚠️ Debes seleccionar un cliente antes de confirmar el pedido.");
            response.sendRedirect("CarritoServlet");
            return;
        }

        try {
            String metodoPago = request.getParameter("metodoPago");
            String ccNumberStr = request.getParameter("ccNumber");
            String fechaStr    = request.getParameter("orderDate");

            long ccNumber = 0;
            if ("tarjeta".equals(metodoPago)) {
                if (ccNumberStr == null || ccNumberStr.trim().isEmpty()) {
                    request.setAttribute("error", "Debes ingresar el número de tarjeta.");
                    request.getRequestDispatcher("carrito.jsp").forward(request, response);
                    return;
                }
                ccNumber = Long.parseLong(ccNumberStr.trim());
            }

            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
            java.util.Date fecha = sdf.parse(fechaStr);

            Pedido pedido = carrito.convertirAPedido(
                    cliente.getCustomerId(),
                    sellerId,
                    ccNumber
            );
            pedido.setFecha(fecha);
            pedido.setEstado("PENDIENTE");

            double totalOriginal = pedido.calcularTotal();
            double descuento     = cliente.getDescuento();
            double totalFinalUSD = totalOriginal * (1 - descuento / 100.0);

            PedidoDAO dao = new PedidoDAO();
            boolean ok = dao.registrarConDescuento(pedido, descuento);

            if (ok) {
                carrito.vaciarTodo();
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
                    mensaje = "✅ Pedido registrado para " + cliente.getNombre() +
                              " | Total: C$ " + String.format("%.2f", totalEnNIO) +
                              " | Equivalente en USD: $" + String.format("%.2f", totalFinalUSD);
                } else {
                    mensaje = "✅ Pedido registrado para " + cliente.getNombre() +
                              " | Total: " + simbolo + String.format("%.2f", totalEnMonedaLocal) +
                              " (" + codigoMoneda + ")" +
                              " | Equivalente en C$: " + String.format("%.2f", totalEnNIO);
                }

                if (descuento > 0) {
                    mensaje += " | Descuento " + (int)descuento + "%: -$" + String.format("%.2f", ahorro);
                }

                request.setAttribute("mensaje", mensaje);
            } else {
                request.setAttribute("error", "Error al registrar el pedido. Verifica el stock de los productos.");
            }

        } catch (NumberFormatException e) {
            request.setAttribute("error", "Verifica que los datos numéricos sean válidos.");
        } catch (Exception e) {
            request.setAttribute("error", "Error: " + e.getMessage());
        }

        doGet(request, response);
    }
}