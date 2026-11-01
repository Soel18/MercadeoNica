package com.mercadeonica.controlador;

import com.mercadeonica.dao.PedidoDAO;
import com.mercadeonica.dao.ProductoDAO;
import com.mercadeonica.modelo.Carrito;
import com.mercadeonica.modelo.Cliente;
import com.mercadeonica.modelo.DetallePedido;
import com.mercadeonica.modelo.Pedido;
import com.mercadeonica.modelo.Producto;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.util.List;

@WebServlet(name = "ClienteMisPedidosServlet", urlPatterns = {"/ClienteMisPedidosServlet"})
public class ClienteMisPedidosServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("cliente") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        Cliente cliente = (Cliente) session.getAttribute("cliente");
        String accion = request.getParameter("accion");
        PedidoDAO dao = new PedidoDAO();

        // ---------- VER DETALLE DE PEDIDO ----------
        if ("verDetalle".equals(accion)) {
            try {
                int orderId = Integer.parseInt(request.getParameter("id"));
                Pedido pedido = dao.buscarPorId(orderId);
                request.setAttribute("pedido", pedido);
                request.setAttribute("detalles", dao.listarDetalles(orderId));
                request.setAttribute("factura", dao.obtenerFactura(orderId));
                request.getRequestDispatcher("cliente-pedido-detalle.jsp").forward(request, response);
                return;
            } catch (NumberFormatException e) {
                System.err.println("❌ ID inválido");
            }
        }
        // ---------- CANCELAR PEDIDO ----------
        else if ("cancelarPedido".equals(accion)) {
            try {
                int orderId = Integer.parseInt(request.getParameter("id"));
                String error = dao.cancelarPedidoConDevolucion(orderId, cliente.getCustomerId());
                if (error == null) {
                    session.setAttribute("mensaje", "✅ Pedido #" + orderId + " cancelado correctamente.");
                } else {
                    session.setAttribute("error", "❌ " + error);
                }
            } catch (NumberFormatException e) {
                session.setAttribute("error", "ID inválido.");
            }
            response.sendRedirect("ClienteMisPedidosServlet");
            return;
        }
        // ---------- REPETIR PEDIDO (CON VALIDACIÓN DE STOCK) ----------
        else if ("repetirPedido".equals(accion)) {
            try {
                int orderId = Integer.parseInt(request.getParameter("id"));
                List<DetallePedido> detalles = dao.listarDetalles(orderId);
                
                Carrito carrito = (Carrito) session.getAttribute("carritoCliente");
                if (carrito == null) {
                    carrito = new Carrito();
                    session.setAttribute("carritoCliente", carrito);
                }

                ProductoDAO prodDao = new ProductoDAO();
                StringBuilder errorMsgs = new StringBuilder();
                int productosAgregados = 0;

                for (DetallePedido d : detalles) {
                    Producto p = prodDao.buscarPorId(d.getProducto().getProductId());
                    if (p == null) {
                        errorMsgs.append("❌ El producto '").append(d.getProducto().getNombre()).append("' ya no existe. ");
                        continue;
                    }
                    
                    int yaEnCarrito = carrito.cantidadDe(p.getProductId());
                    int disponibleReal = p.getCantidadDisponible();
                    
                    if (yaEnCarrito + d.getCantidad() > disponibleReal) {
                        int restante = disponibleReal - yaEnCarrito;
                        if (restante <= 0) {
                            errorMsgs.append("❌ Ya tienes ").append(yaEnCarrito).append(" de '").append(p.getNombre()).append("' y no hay más stock. ");
                        } else {
                            errorMsgs.append("⚠️ Solo quedan ").append(restante).append(" de '").append(p.getNombre()).append("'. ");
                        }
                        continue;
                    }
                    
                    carrito.agregarProducto(p, d.getCantidad());
                    productosAgregados++;
                }

                if (productosAgregados > 0) {
                    session.setAttribute("mensaje", "✅ " + productosAgregados + " producto(s) del pedido #" + orderId + " agregados al carrito.");
                }
                if (errorMsgs.length() > 0) {
                    session.setAttribute("error", errorMsgs.toString());
                }

                response.sendRedirect("ClienteCarritoServlet");
                return;
            } catch (Exception e) {
                session.setAttribute("error", "Error al repetir el pedido: " + e.getMessage());
            }
            response.sendRedirect("ClienteMisPedidosServlet");
            return;
        }

        // ---------- LISTAR PEDIDOS DEL CLIENTE ----------
        String filtro = request.getParameter("filtro");
        List<Pedido> pedidos = dao.listarPedidosDeCliente(cliente.getCustomerId(), filtro);

        request.setAttribute("pedidos", pedidos);
        request.setAttribute("filtroActual", filtro);
        request.getRequestDispatcher("cliente-mis-pedidos.jsp").forward(request, response);
    }
}