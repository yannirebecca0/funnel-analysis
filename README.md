# [Finding-first title, e.g. "Where Premium Shoppers Abandon Carts, and What It Costs"]

[One sentence: what you analyzed, the headline result with a number, and the recommendation.]

**Live dashboard:** [Tableau Public link] | **Summary:** [SUMMARY.md](SUMMARY.md)

![Funnel and leak heatmap](outputs/figures/dashboard_1.png)

## Business question
Which product categories and price tiers lose the most shoppers between cart and purchase, how much revenue is that worth, and what should a team test first?

## Data
REES46 eCommerce behavior data (Kaggle), October 2019: [N] events, [N] users. Analysis uses a 10% random user sample (all events of each sampled user, `hash(user_id) % 10 = 0`) to fit an 8 GB laptop. Raw data is not included; see the Kaggle page for the license.

## Key findings
1. [Finding 1 with a number]
2. [Finding 2 with a number]
3. [Finding 3 with a number]

## Method
- **Sessionization (SQL, DuckDB):** a new session after 30 minutes of inactivity. Sensitivity: 10 / 30 / 60 minutes gave [a / b / c] sessions and [did / did not] change the conclusions.
- **Funnel definition:** a session reaches Cart only after a View, and Purchase only after a Cart, in that order. [x]% of purchases skip a step (usually a cart in an earlier session).
- **Segmentation:** category x price tier (quartiles of average product price). Simpson's paradox check: [found / not found], plus mix-adjusted rates.
- **Survival analysis:** Kaplan-Meier time from cart to purchase, 7-day horizon, by price tier.
- **Prediction:** XGBoost on a session's first 5 events, time-based split, SHAP for explanation. Test PR-AUC [x] versus [base rate] baseline.
- **Experiment design:** power analysis and test plan for [intervention].
- **Impact sizing:** low / base / high scenarios plus a Monte Carlo range.

## Results
[Embed the 3 or 4 best figures: heatmap, survival curves, SHAP summary, Sankey.]

## Recommendation and experiment plan
[Intervention, metric, guardrails, sample size, duration, decision rule.]

## Impact estimate
[Your impact statement from Phase 5 with the P10 to P90 range and assumptions.]

## Data quality log
[One line per check from Phase 1 and 2: what you found, what you did.]

## Limitations
- One store, October 2019, 10% user sample; results may not generalize
- Revenue figures rest on stated assumptions (reach, lift, margin, cost)
- The model shows association, not causation
- Users can have sessions outside the data window (left-censoring)

## How to reproduce
1. Download the CSV(s) into data/raw/
2. pip install -r requirements.txt
3. Run the SQL files in sql/ in numeric order with DuckDB
4. Run the notebooks in notebooks/ in numeric order
