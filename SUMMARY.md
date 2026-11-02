# First-Time Buyers Drive Cart Abandonment: one-page summary

**Problem:** Shoppers who add products to their cart often leave without buying, and it is not clear which product categories and price tiers lose the most of them. This project finds where that loss is largest, what it is worth in revenue, and what a team should test first.

**Approach:** REES46 e-commerce events from October 2019 (42.4M events store-wide; analysis on a 10% random user sample of 4.2M events). Events were grouped into sessions using a 30-minute inactivity gap, tested at 10 and 60 minutes, and run through a strict view → cart → purchase funnel cut by category, price tier and first-time vs returning buyer. Over half of purchases have no logged cart, so every gap is tested at both ends of a cart-logging bound and for Simpson's paradox. Kaplan-Meier curves measure how long carts take to convert. XGBoost with SHAP independently checks what predicts a purchase. A power analysis sizes the A/B test, and a Monte Carlo simulation sizes the revenue impact.

**Findings:**
- Electronics holds 83% of abandoned cart value (about $82M a month store-wide). The premium tier looks like the biggest leak, but its conversion gap is a mix effect and vanishes under the logging bound.
- First-time buyers make up 64% of electronics carts and convert at 43%, against 74% for returning buyers. The gap holds under the logging bound (55% vs 83%), in every price tier and outside electronics. It is also the model's strongest predictor.
- 81% of purchases within 7 days of the cart come within 5 minutes, and only 3% after a day. The decision is made in the session, so a later reminder email reaches few buyers.

**Recommendation:** Run a 2-week A/B test, randomized by user, of an in-cart panel for first-time electronics buyers showing the delivery date, returns policy and installment options. Use 39,097 carts per arm to detect a +1 point lift in the 7-day purchase rate (baseline 46.5%).

**Expected impact:** $1.42M per month in incremental revenue ($0.63M to $2.35M), or about $208K in gross profit. Each point of lift is worth about $1.0M a month. This assumes the panel closes 0–12% of the first-time buyer gap (most likely 5%) and reaches 85–100% of carts.

**What I would do next:**
- Run the test and read it out against the preset decision rule, including the pre-registered model-score tercile analysis
- Fix cart-event logging: 56% of purchases have no cart before them, and this caps how precise any funnel metric can be
- Add pre-October purchase history, device and traffic-source data, and repeat on November 2019 to check the findings hold
