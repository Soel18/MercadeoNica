package com.mercadeonica.controlador;

import com.mercadeonica.dao.ClienteDAO;
import com.mercadeonica.modelo.Cliente;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

@WebServlet(name = "ClienteLoginServlet", urlPatterns = {"/ClienteLoginServlet"})
public class ClienteLoginServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        System.out.println("========== ClienteLoginServlet.doPost ==========");

        String email    = request.getParameter("email");
        String password = request.getParameter("password");

        System.out.println("📧 Email: " + email);

        ClienteDAO dao = new ClienteDAO();
        Cliente cliente = dao.login(email, password);

        if (cliente != null) {
            HttpSession session = request.getSession();
            session.setAttribute("cliente", cliente);
            session.setAttribute("clienteNombre", cliente.getNombre());
            session.setAttribute("clienteId", cliente.getCustomerId());

            System.out.println("✅ Sesión de cliente creada: " + cliente.getNombre());

            response.sendRedirect("cliente-menu.jsp");
        } else {
            request.setAttribute("error", "Credenciales inválidas o cliente inactivo.");
            request.getRequestDispatcher("cliente-login.jsp").forward(request, response);
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect("cliente-login.jsp");
    }
}