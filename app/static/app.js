const state = window.__ASTER__ || { catalog: {}, recent_orders: [] };

const catalog = state.catalog || {};
const finishes = catalog.finishes || [];
const memory = catalog.memory || [];
const delivery = catalog.delivery || [];
const stats = catalog.stats || [];

const finishSelect = document.getElementById("finish");
const memorySelect = document.getElementById("memory");
const deliverySelect = document.getElementById("delivery_speed");
const quantityInput = document.getElementById("quantity");
const quantityValue = document.getElementById("quantity-value");
const orderForm = document.getElementById("order-form");
const recentOrders = document.getElementById("recent-orders");
const timeline = document.getElementById("workflow-timeline");
const featureGrid = document.getElementById("feature-grid");
const statStrip = document.getElementById("stat-strip");
const quoteTotal = document.getElementById("quote-total");
const quoteBase = document.getElementById("quote-base");
const quoteFinish = document.getElementById("quote-finish");
const quoteMemory = document.getElementById("quote-memory");
const quoteDelivery = document.getElementById("quote-delivery");

let activeOrderId = null;
let activeOrderTimer = null;

function dollars(cents) {
  return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 0 }).format(cents / 100);
}

function fillSelect(select, options) {
  select.innerHTML = options
    .map(
      (option) =>
        `<option value="${option.id}" data-price="${option.price_cents}">${option.label} — ${option.subtitle}</option>`,
    )
    .join("");
}

function renderStats() {
  statStrip.innerHTML = stats
    .map(
      (item) => `
        <li>
          <strong>${item.value}</strong>
          <span>${item.label} · ${item.detail}</span>
        </li>`,
    )
    .join("");
}

function renderFeatures() {
  const cards = [
    {
      title: "Luxury front-end",
      body: "Large type, restrained color, and a calm layout that feels more like a launch keynote than a dashboard.",
    },
    {
      title: "Temporal-native workflow",
      body: "Order placement becomes a durable workflow with retries, event history, and clear state transitions.",
    },
    {
      title: "Container-first backend",
      body: "FastAPI, worker, Postgres, and Temporal all compose cleanly in Docker and map to ECS in AWS.",
    },
    {
      title: "Operational memory",
      body: "Every step is written to the database so the UI can show what happened, not just the final answer.",
    },
  ];

  featureGrid.innerHTML = cards
    .map(
      (card) => `
        <article class="feature">
          <h3>${card.title}</h3>
          <p>${card.body}</p>
        </article>`,
    )
    .join("");
}

function updateQuote() {
  const finish = finishes.find((item) => item.id === finishSelect.value);
  const mem = memory.find((item) => item.id === memorySelect.value);
  const del = delivery.find((item) => item.id === deliverySelect.value);
  const quantity = Number(quantityInput.value);
  const base = catalog.product?.base_price_cents || 0;
  const finishPrice = finish?.price_cents || 0;
  const memoryPrice = mem?.price_cents || 0;
  const deliveryPrice = del?.price_cents || 0;
  const total = (base + finishPrice + memoryPrice) * quantity + deliveryPrice;

  quantityValue.textContent = `${quantity} ${quantity === 1 ? "unit" : "units"}`;
  quoteBase.textContent = dollars(base * quantity);
  quoteFinish.textContent = dollars(finishPrice * quantity);
  quoteMemory.textContent = dollars(memoryPrice * quantity);
  quoteDelivery.textContent = dollars(deliveryPrice);
  quoteTotal.textContent = dollars(total);
}

function buildTimeline(events = []) {
  const steps = events.length
    ? events
    : [
        { step: "waiting", message: "Place an order to watch Temporal build the narrative.", created_at: "" },
      ];

  timeline.innerHTML = steps
    .map(
      (event) => `
        <div class="timeline-item">
          <div class="timeline-dot"></div>
          <div>
            <h4>${event.step}</h4>
            <p>${event.message}</p>
          </div>
        </div>`,
    )
    .join("");
}

function renderRecentOrders(orders = []) {
  if (!orders.length) {
    recentOrders.innerHTML = `<div class="timeline-item"><div class="timeline-dot"></div><div><h4>No orders yet</h4><p>Use the configurator above to place the first studio build.</p></div></div>`;
    return;
  }

  recentOrders.innerHTML = `
    <table>
      <thead>
        <tr>
          <th>Order</th>
          <th>Finish</th>
          <th>Memory</th>
          <th>Status</th>
          <th>Total</th>
        </tr>
      </thead>
      <tbody>
        ${orders
          .map(
            (order) => `
              <tr>
                <td>
                  <strong>${order.customer_name}</strong><br />
                  <span class="muted">${order.id}</span>
                </td>
                <td>${order.finish}</td>
                <td>${order.memory}</td>
                <td><span class="badge">${order.status}</span></td>
                <td>${dollars(order.total_cents)}</td>
              </tr>`,
          )
          .join("")}
      </tbody>
    </table>`;
}

async function refreshRecentOrders() {
  const response = await fetch("/api/orders/recent");
  const data = await response.json();
  renderRecentOrders(data.orders || []);
}

async function refreshOrder(orderId) {
  const response = await fetch(`/api/orders/${orderId}`);
  if (!response.ok) return;
  const data = await response.json();
  buildTimeline(data.events || []);
  return data;
}

function stopActivePolling() {
  if (activeOrderTimer) {
    clearInterval(activeOrderTimer);
    activeOrderTimer = null;
  }
}

function startActivePolling(orderId) {
  activeOrderId = orderId;
  stopActivePolling();
  activeOrderTimer = setInterval(async () => {
    if (!activeOrderId) {
      stopActivePolling();
      return;
    }

    const data = await refreshOrder(activeOrderId);
    if (!data) return;

    const status = data.order?.status || data.order?.workflow_status;
    if (status === "complete" || status === "completed") {
      stopActivePolling();
      await refreshRecentOrders();
      const submitButton = orderForm.querySelector("button[type='submit']");
      submitButton.textContent = "Reserve my build";
      submitButton.disabled = false;
    }
  }, 2000);
}

function setInitialSelections() {
  fillSelect(finishSelect, finishes);
  fillSelect(memorySelect, memory);
  fillSelect(deliverySelect, delivery);
  if (finishes[0]) finishSelect.value = finishes[0].id;
  if (memory[1]) memorySelect.value = memory[1].id;
  if (delivery[1]) deliverySelect.value = delivery[1].id;
}

function wireForm() {
  [finishSelect, memorySelect, deliverySelect, quantityInput].forEach((element) => {
    element.addEventListener("change", updateQuote);
    element.addEventListener("input", updateQuote);
  });

  orderForm.addEventListener("submit", async (event) => {
    event.preventDefault();
    const submitButton = orderForm.querySelector("button[type='submit']");
    submitButton.disabled = true;
    submitButton.textContent = "Launching workflow...";

    const payload = {
      customer_name: document.getElementById("customer_name").value,
      email: document.getElementById("email").value,
      finish: finishSelect.value,
      memory: memorySelect.value,
      delivery_speed: deliverySelect.value,
      engraving: document.getElementById("engraving").value || null,
      quantity: Number(quantityInput.value),
    };

    try {
      const response = await fetch("/api/orders", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      if (!response.ok) {
        throw new Error(await response.text());
      }

      const data = await response.json();
      await refreshRecentOrders();
      await refreshOrder(data.order_id);
      startActivePolling(data.order_id);
      submitButton.textContent = "Workflow running";
    } catch (error) {
      console.error(error);
      submitButton.textContent = "Try again";
      submitButton.disabled = false;
      alert("Temporal is not ready yet. Make sure the stack is running before placing an order.");
    }
  });
}

function boot() {
  renderStats();
  renderFeatures();
  setInitialSelections();
  wireForm();
  updateQuote();
  renderRecentOrders(state.recent_orders || []);
  buildTimeline([]);
  refreshRecentOrders().catch(() => null);
}

boot();
