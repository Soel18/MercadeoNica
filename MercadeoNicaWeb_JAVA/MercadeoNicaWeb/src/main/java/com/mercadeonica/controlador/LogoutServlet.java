package com.mercadeonica.controlador;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

/**
 * Servlet de logout UNIFICADO.
 * Sirve para vendedores, admins y clientes por igual.
 */
@WebServlet(name = "LogoutServlet", urlPatterns = {"/LogoutServlet"})
public class LogoutServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session != null) {

            // Detectar nombre (vendedor o cliente) para log
            String nombre = (String) session.getAttribute("nombreUsuario");
            if (nombre == null) {
                nombre = (String) session.getAttribute("clienteNombre");
            }

            // Limpiar TODOS los atributos posibles
            session.removeAttribute("vendedor");
            session.removeAttribute("nombreUsuario");
            session.removeAttribute("rolUsuario");
            session.removeAttribute("cliente");
            session.removeAttribute("clienteNombre");
            session.removeAttribute("clienteId");
            session.removeAttribute("carrito");         // carrito vendedor
            session.removeAttribute("carritoCliente");  // carrito cliente

            session.invalidate();

            System.out.println("👋 Sesión cerrada: "
                    + (nombre != null ? nombre : "usuario anónimo"));
        }

        response.sendRedirect("login.jsp");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doGet(request, response);
    }
}