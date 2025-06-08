const userServiceUrl = "http://10.110.45.26/users"; // User Service URL
const productServiceUrl = "http://10.110.45.26/products"; // Product Service URL
const saleServiceUrl = "http://10.110.45.26/sales"; // Sale Service URL

// Elements
const loginBtn = document.getElementById("login-btn");
const registerBtn = document.getElementById("register-btn");
const loginFormContainer = document.getElementById("login-form-container");
const registerFormContainer = document.getElementById("register-form-container");
const fetchProductsBtn = document.getElementById("fetch-products");
const productList = document.getElementById("product-list");
const createProductContainer = document.getElementById("create-product-container");
const buyProductContainer = document.getElementById("buy-product-container");

// User Authentication Data
let userRole = null;  // This will hold the role of the logged-in user (buyer/vendor)

// Toggle Login/Register Forms
loginBtn.addEventListener("click", () => {
    loginFormContainer.style.display = 'block';
    registerFormContainer.style.display = 'none';
});

registerBtn.addEventListener("click", () => {
    registerFormContainer.style.display = 'block';
    loginFormContainer.style.display = 'none';
});

// Register user
document.getElementById("register-form").addEventListener("submit", async (e) => {
    e.preventDefault();
    const email = document.getElementById("register-email").value;
    const name = document.getElementById("register-name").value;
    const password = document.getElementById("register-password").value;
    const isVendor = document.getElementById("register-vendor").checked;

    const response = await fetch(`${userServiceUrl}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name, password, email, is_vendor: isVendor }),
    });
    const data = await response.json();
    alert("User Registered: " + data.name);
    loginFormContainer.style.display = 'block';
    registerFormContainer.style.display = 'none';
});


// Login user
document.getElementById("login-form").addEventListener("submit", async (e) => {
    e.preventDefault();
    const email = document.getElementById("login-email").value;
    const password = document.getElementById("login-password").value;

    const response = await fetch(`${userServiceUrl}/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password }),
    });
    const data = await response.json();
    if (data.access_token) {
        alert("Login Successful");
        localStorage.setItem("access_token", data.access_token);
        localStorage.setItem("user_role", data.role);
        userRole = data.role;  // Save the user's role (buyer/vendor)
        checkUserRole();  // Display appropriate forms based on role
        loginFormContainer.style.display = 'none'; // Hide login form after successful login
    } else {
        alert("Login Failed");
    }
});

async function handleCreateProduct(e) {
    e.preventDefault();
    const token = localStorage.getItem("access_token");
    const name = document.getElementById("product-name").value;
    const price = document.getElementById("product-price").value;
    const stock = document.getElementById("product-stock").value;
    const description = document.getElementById("product-description").value;

    const response = await fetch(`${productServiceUrl}`, {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
        body: JSON.stringify({ name, price, stock, description }),
    });
    const data = await response.json();
    if (response.status == 200){
        alert("Product Created: " + data.name);
    } else if (response.status == 400) {
        alert("Error: " + data.detail);
    }
}

// Fetch and display products
fetchProductsBtn.addEventListener("click", async () => {
    const token = localStorage.getItem("access_token");

    const response = await fetch(`${productServiceUrl}`, {
        headers: {
            "Authorization": `Bearer ${token}`,
        }
    })

    if (response.status === 401) {
        alert("Session expired or unauthorized. Please log in again.");
        localStorage.removeItem("access_token");
        return;
    }

    const products = await response.json();
    productList.innerHTML = ""; // Clear existing products
    products.forEach((product) => {
        const productElement = document.createElement("div");
        productElement.classList.add("product");
        productElement.setAttribute("data-product-id", product.id);
        const productBuyBtn = document.createElement("button");
        productBuyBtn.addEventListener("click", async (e) => {
            e.preventDefault();
            const quantity = prompt("Enter quantity to buy:");
            if (quantity && !isNaN(quantity) && quantity > 0) {
                buyProduct(product.id, quantity);
            } else {
                alert("Invalid quantity entered.");
            }
        });
        productElement.innerHTML = `
            <strong>${product.name}</strong><br>
            Price: $${product.price}<br>
            Description: ${product.description}<br>
            Stock: ${product.stock}
        `;
        productBuyBtn.textContent = "Buy";
        productElement.appendChild(productBuyBtn);
        productList.appendChild(productElement);
    });
});

function buyProduct(productId, quantity) {
    const token = localStorage.getItem("access_token");
    fetch(`${saleServiceUrl}`, {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
        body: JSON.stringify({ product_id: productId, quantity }),
    })
    .then(response => response.json())
    .then(data => {
        if (data.id) {
            alert("Purchase Successful: " + data.id);
            fetchProductsBtn.click();
        } else {
            alert("Purchase Failed: " + data.detail);
        }
    })
    .catch(error => console.error("Error:", error));
}

// Check User Role and Show Appropriate Form
function checkUserRole() {
    if (userRole === "vendor") {
        createProductContainer.style.display = 'block';
        buyProductContainer.style.display = 'none';
        const form = document.getElementById("create-product-form");
        form.removeEventListener("submit", handleCreateProduct); // Avoid duplicates
        form.addEventListener("submit", handleCreateProduct);
    } else if (userRole === "customer") {
        createProductContainer.style.display = 'none';
        buyProductContainer.style.display = 'block';
    }   
}