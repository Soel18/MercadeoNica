package com.mercadeonica.controlador;

import com.mercadeonica.dao.ClienteDAO;
import com.mercadeonica.dao.ProductoDAO;
import com.mercadeonica.modelo.Carrito;
import com.mercadeonica.modelo.Cliente;
import com.mercadeonica.modelo.Producto;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

@WebServlet(name = "CarritoServlet", urlPatterns = {"/CarritoServlet"})
public class CarritoServlet extends HttpServlet {

    /**
     * Obtiene o crea el carrito del vendedor en la sesión.
     */
    private Carrito obtenerCarrito(HttpSession session) {
        Carrito carrito = (Carrito) session.getAttribute("carrito");
        if (carrito == null) {
            carrito = new Carrito();
            session.setAttribute("carrito", carrito);
        }
        return carrito;
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("vendedor") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        Carrito carrito = obtenerCarrito(session);
        String accion = request.getParameter("accion");

        // ============================================================
        // VACIAR CARRITO
        // ============================================================
        if ("vaciar".equals(accion)) {
            carrito.vaciar();
            response.sendRedirect("CarritoServlet");
            return;
        }

        // ============================================================
        // ELIMINAR PRODUCTO
        // ============================================================
        if ("eliminar".equals(accion)) {
            String productIdStr = request.getParameter("productId");
            if (productIdStr != null && !productIdStr.trim().isEmpty()) {
                try {
                    int productId = Integer.parseInt(productIdStr.trim());
                    carrito.eliminarProducto(productId);
                } catch (NumberFormatException e) {
                    System.err.println("❌ ProductId inválido");
                }
            }
            response.sendRedirect("CarritoServlet");
            return;
        }

        // ============================================================
        // QUITAR CLIENTE ASIGNADO
        // ============================================================
        if ("quitarCliente".equals(accion)) {
            carrito.setCliente(null);
            request.setAttribute("mensaje", "Cliente removido del carrito.");
            response.sendRedirect("CarritoServlet");
            return;
        }

        // ============================================================
        // SELECCIONAR CLIENTE
        // ============================================================
        if ("seleccionarCliente".equals(accion)) {
            String cidStr = request.getParameter("customerId");
            if (cidStr != null && !cidStr.trim().isEmpty()) {
                try {
                    int cid = Integer.parseInt(cidStr.trim());
                    ClienteDAO cdao = new ClienteDAO();
                    Cliente c = cdao.buscarPorId(cid);
                    if (c != null) {
                        carrito.setCliente(c);
                        request.setAttribute("mensaje",
                            "✅ Cliente seleccionado: " + c.getNombre() +
                            " (" + c.getCategoriaNombre() + " - " + c.getDescuento() + "% desc.)");
                    } else {
                        request.setAttribute("error", "Cliente no encontrado.");
                    }
                } catch (NumberFormatException e) {
                    request.setAttribute("error", "ID de cliente inválido.");
                }
            } else {
                request.setAttribute("error", "Debes seleccionar un cliente.");
            }
        }

        // ============================================================
        // ADVERTENCIA SI HAY PRODUCTOS PERO NO CLIENTE
        // ============================================================
        if (!carrito.tieneCliente() && !carrito.estaVacio()) {
            request.setAttribute("error",
                "⚠️ Tienes productos en el carrito pero no has seleccionado un cliente. " +
                "Selecciona uno para continuar.");
        }

        // ============================================================
        // CARGAR LISTA DE CLIENTES PARA EL SELECTOR
        // ============================================================
        ClienteDAO clienteDAO = new ClienteDAO();
        request.setAttribute("clientes", clienteDAO.listar());

        request.getRequestDispatcher("carrito.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("vendedor") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        Carrito carrito = obtenerCarrito(session);
        String accion = request.getParameter("accion");

        // ============================================================
        // AGREGAR PRODUCTO AL CARRITO
        // ============================================================
        if ("agregar".equals(accion)) {

            // 🔒 Validar que exista un cliente asignado antes de agregar
            if (!carrito.tieneCliente()) {
                request.setAttribute("error",
                    "⚠️ Debes seleccionar un cliente antes de agregar productos.");
                response.sendRedirect("CarritoServlet");
                return;
            }

            String productIdStr = request.getParameter("productId");
            String cantidadStr  = request.getParameter("cantidad");

            try {
                int productId = Integer.parseInt(productIdStr.trim());
                int cantidad  = Integer.parseInt(cantidadStr.trim());

                if (cantidad <= 0) {
                    request.setAttribute("error", "La cantidad debe ser mayor a 0.");
                    response.sendRedirect("CarritoServlet");
                    return;
                }

                ProductoDAO pdao = new ProductoDAO();
                Producto p = pdao.buscarPorId(productId);

                if (p == null) {
                    request.setAttribute("error", "Producto no encontrado.");
                    response.sendRedirect("CarritoServlet");
                    return;
                }

                if (p.getCantidadDisponible() < cantidad) {
                    request.setAttribute("error",
                        "Stock insuficiente de '" + p.getNombre() +
                        "'. Disponible: " + p.getCantidadDisponible());
                    response.sendRedirect("CarritoServlet");
                    return;
                }

                carrito.agregarProducto(p, cantidad);
                System.out.println("✅ Producto agregado al carrito de " +
                                   carrito.getCliente().getNombre());

            } catch (NumberFormatException e) {
                request.setAttribute("error", "Datos inválidos.");
            }
        }

        response.sendRedirect("CarritoServlet");
    }
}