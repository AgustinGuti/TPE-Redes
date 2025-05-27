const userServiceUrl = "http://localhost:8000/users"; // User Service URL
const productServiceUrl = "http://localhost:8000/products"; // Product Service URL

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

// Fetch and display products
fetchProductsBtn.addEventListener("click", async () => {
    const response = await fetch(`${productServiceUrl}`);
    const products = await response.json();
    productList.innerHTML = ""; // Clear existing products
    products.forEach((product) => {
        const productElement = document.createElement("div");
        productElement.classList.add("product");
        productElement.innerHTML = `
            <strong>${product.name}</strong><br>
            Price: $${product.price}<br>
            Description: ${product.description}<br>
            Stock: ${product.stock}
        `;
        productList.appendChild(productElement);
    });

    const form = document.getElementById("create-product-form");
    form.removeEventListener("submit", handleCreateProduct); // Just in case
    form.addEventListener("submit", handleCreateProduct);

    async function handleCreateProduct(e) {
        e.preventDefault();
        const name = document.getElementById("product-name").value;
        const price = document.getElementById("product-price").value;
        const stock = document.getElementById("product-stock").value;
        const vendorId = document.getElementById("product-vendor-id").value;
        const description = document.getElementById("product-description").value;

        const response = await fetch(`${productServiceUrl}`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ name, price, stock, vendor_id: vendorId, description }),
        });
        const data = await response.json();
        alert("Product Created: " + data.name);
    }


    // Buy Product (Buyer)
    document.getElementById("buy-product-form").addEventListener("submit", async (e) => {
        e.preventDefault();
        const productId = document.getElementById("product-id-to-buy").value;
        const quantity = document.getElementById("quantity-to-buy").value;

        const response = await fetch(`${productServiceUrl}/sales`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ product_id: productId, quantity }),
        });
        const data = await response.json();
        alert("Purchase Successful: " + data.id);
    });
});

// Check User Role and Show Appropriate Form
function checkUserRole() {
    if (userRole === "vendor") {
        createProductContainer.style.display = 'block';
        buyProductContainer.style.display = 'none';
    } else if (userRole === "buyer") {
        createProductContainer.style.display = 'none';
        buyProductContainer.style.display = 'block';
    }
}