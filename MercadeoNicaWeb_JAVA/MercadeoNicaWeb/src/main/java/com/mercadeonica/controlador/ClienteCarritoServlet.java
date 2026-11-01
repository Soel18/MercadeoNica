package com.mercadeonica.controlador;

import com.mercadeonica.dao.ProductoDAO;
import com.mercadeonica.modelo.Carrito;
import com.mercadeonica.modelo.Producto;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

@WebServlet(name = "ClienteCarritoServlet", urlPatterns = {"/ClienteCarritoServlet"})
public class ClienteCarritoServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        System.out.println("========== ClienteCarritoServlet.doGet ==========");

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("cliente") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        Carrito carrito = (Carrito) session.getAttribute("carritoCliente");
        if (carrito == null) {
            carrito = new Carrito();
            session.setAttribute("carritoCliente", carrito);
        }

        String accion = request.getParameter("accion");

        if ("eliminar".equals(accion)) {
            try {
                int productId = Integer.parseInt(request.getParameter("productId"));
                carrito.eliminarProducto(productId);
                System.out.println("🗑️ Producto eliminado: " + productId);
                session.setAttribute("mensaje", "🗑️ Producto eliminado del carrito.");
            } catch (NumberFormatException e) {
                System.err.println("ID inválido: " + e.getMessage());
                session.setAttribute("error", "ID de producto inválido.");
            }
        } else if ("vaciar".equals(accion)) {
            session.removeAttribute("carritoCliente");
            System.out.println("🗑️ Carrito vaciado");
            session.setAttribute("mensaje", "🗑️ Carrito vaciado correctamente.");
            response.sendRedirect("cliente-carrito.jsp");
            return;
        }

        response.sendRedirect("cliente-carrito.jsp");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        System.out.println("========== ClienteCarritoServlet.doPost ==========");

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("cliente") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        Carrito carrito = (Carrito) session.getAttribute("carritoCliente");
        if (carrito == null) {
            carrito = new Carrito();
            session.setAttribute("carritoCliente", carrito);
        }

        String accion = request.getParameter("accion");

        if ("agregar".equals(accion)) {
            try {
                int productId = Integer.parseInt(request.getParameter("productId"));
                int cantidad  = Integer.parseInt(request.getParameter("cantidad"));

                if (cantidad <= 0) {
                    session.setAttribute("error", "⚠️ La cantidad debe ser mayor a 0.");
                    response.sendRedirect("ClienteCarritoServlet");
                    return;
                }

                ProductoDAO dao = new ProductoDAO();
                Producto p = dao.buscarPorId(productId);

                if (p == null) {
                    session.setAttribute("error", "❌ El producto no existe.");
                    response.sendRedirect("ClienteCarritoServlet");
                    return;
                }

                // Cuánto ya tiene en el carrito
                int yaEnCarrito = carrito.cantidadDe(productId);
                int disponibleReal = p.getCantidadDisponible();

                if (yaEnCarrito + cantidad > disponibleReal) {
                    int restante = disponibleReal - yaEnCarrito;
                    if (restante <= 0) {
                        session.setAttribute("error",
                            "⚠️ Ya tienes " + yaEnCarrito + " unidad(es) de '" + p.getNombre() +
                            "' en el carrito. Stock disponible: " + disponibleReal + ".");
                    } else {
                        session.setAttribute("error",
                            "⚠️ Stock insuficiente. Solo puedes agregar " + restante +
                            " unidad(es) más de '" + p.getNombre() + "'.");
                    }
                    response.sendRedirect("ClienteCarritoServlet");
                    return;
                }

                carrito.agregarProducto(p, cantidad);
                System.out.println("✅ Agregado: " + p.getNombre() + " x" + cantidad);
                session.setAttribute("mensaje",
                    "✅ Agregado al carrito: " + p.getNombre() + " x" + cantidad);

            } catch (NumberFormatException e) {
                System.err.println("❌ Error: " + e.getMessage());
                session.setAttribute("error", "⚠️ Datos inválidos.");
            }
        }

        response.sendRedirect("ClienteCarritoServlet");
    }
}