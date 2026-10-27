# Used Car Selling Price: Linear Regression Analysis

An R project that models the selling price of used cars (Car details v3 dataset) using linear regression. It covers data cleaning, exploratory analysis, two required regression models, model comparison with train/test validation, regression diagnostics, and an optional extension with a log-price model.

## Dataset

- **File:** `Car details v3.csv`
- **Size:** 8,128 rows and 13 columns
- **Key variables:** `selling_price` (₹), `km_driven`, `year`, `fuel`, `transmission`, `max_power`, `mileage`, `engine`
- **Target variable:** `selling_price`

## Requirements

- R (4.x recommended)
- Required packages: `tidyverse`, `broom`, `scales`
- Optional packages (the script skips the related step if missing): `patchwork`, `lmtest`, `car`

```r
install.packages(c("tidyverse", "broom", "scales", "patchwork", "lmtest", "car"))
```

## How to Run

1. Open `car_price_regression.R` in RStudio.
2. Set `csv_path` at the top of the script to the location of `Car details v3.csv`.
3. Run the whole script (Source or Ctrl+Shift+Enter).

If comments or the ₹ symbol appear garbled, use *File → Reopen with Encoding → UTF-8*.

## Project Structure

```
car_price_regression.R      Main analysis script
plots/                      Saved figures (created automatically)
output/                     Saved result tables in CSV format (created automatically)
README.md                   This file
```

## Analysis Overview

### Part 1: Data Import and Inspection
Reads the CSV and inspects its structure: number of rows and columns, variable names, data types, and missing values per column.
**Functions:** `read_csv()`, `dim()`, `names()`, `glimpse()`, `colSums(is.na())`

### Part 2: Data Cleaning
- Converts text specification columns (`mileage`, `engine`, `max_power`) to numeric. Values recorded as `0` or a bare unit are treated as missing.
- Detects and removes exact duplicate rows (1,202 found, leaving 6,926 rows).
- Reports implausible values before filtering (non-positive price or distance, distances above 300,000 km, years outside 1983 to 2020).
- Filters the data and creates `car_age = 2020 - year`. The final modelling sample has 6,908 rows.

**Functions:** `mutate()`, `filter()`, `distinct()`

### Part 3: Descriptive Statistics
Computes the mean, median, standard deviation, minimum, and maximum of `selling_price`, `km_driven`, and `car_age`.
**Functions:** `summary()`, `summarise()`, `mean()`, `median()`
**Output:** `output/descriptive_statistics.csv`

### Part 4: Exploratory Data Analysis
- Price distribution on the raw and log scales, which shows the strong right skew of price.
- Selling price versus distance driven, with a fitted line.
- Selling price versus car age, on the raw scale and with a log price axis.
- Selling price versus fuel efficiency.

**Functions:** `ggplot()`, `geom_histogram()`, `geom_point()`, `geom_smooth()`
**Output:** `plots/01_` to `plots/05_`

### Part 5: Model 1, Simple Linear Regression
The baseline model: `selling_price ~ km_driven`. Reports coefficients, confidence intervals, and R².

### Part 6: Model 2, Multiple Linear Regression
Adds car age: `selling_price ~ km_driven + car_age`. An F-test (`anova(model1, model2)`) checks whether the extra variable significantly improves the fit.

### Part 7: Model Comparison and Validation
- **In-sample:** R², adjusted R², residual standard error, AIC, and BIC for both models.
- **Out-of-sample:** an 80/20 train-test split (`set.seed(123)`). Both models are fitted on the training set and evaluated on the test set using RMSE and MAE.

**Output:** `output/model_comparison.csv`, `output/test_errors.csv`

### Part 8: Regression Diagnostics and Results Output
- Standard diagnostic plots for Model 2: residuals versus fitted (linearity), Q-Q plot (normality), scale-location (constant variance), and residuals versus leverage (influence).
- Breusch-Pagan test for constant variance.
- Variance inflation factors (VIF) for collinearity.
- Influential observations identified with Cook's distance (threshold 4/n).
- Final tables written to CSV with `write_csv()`.

**Output:** `output/model2_coefficients.csv`, `output/influential_observations.csv`

### Extension (Optional): Log-Price Models
Raw price is highly skewed and its relationship with car age is curved, so the extension models the logarithm of price.

- **Model 3:** `log(price) ~ km + age`
- **Model 4:** `log(price) ~ km + age + power + transmission + fuel`
- Uses a sample of 6,613 Diesel and Petrol cars with known engine power, with models compared on a common train-test split (log predictions are converted back to rupees).
- Additional figures: distance versus price by car age group and fuel type, a coefficient plot showing the percentage effect of each variable on price, predicted price curves, and actual versus predicted prices.

**Output:** `plots/E1_` to `plots/E4_`, `output/extension_model_comparison.csv`, `output/model4_percent_effects.csv`

## Key Results

| Model | R² | Test RMSE (₹) | Test MAE (₹) |
|---|---|---|---|
| Model 1: km | 0.044 | 457,793 | 275,965 |
| Model 2: km + age | 0.188 | 416,565 | 224,836 |

- Adding car age significantly improves the model (F = 1226.8, p < 2.2e-16).
- In Model 2, car age has a strong negative effect (about ₹54,461 lower price per extra year), while distance driven is not significant (p = 0.259).
- Diagnostics show heteroscedasticity (Breusch-Pagan p < 2.2e-16) and 206 influential observations, mostly luxury cars with very high prices. This motivates the log-price extension.
- In the extension, Model 4 reaches R² of about 0.83 and a test RMSE of about ₹184,209.

## Assumptions and Limitations

- Distances above 300,000 km are treated as outliers and excluded. Change the filter in Part 2.4 if a different rule is required.
- Car age uses 2020 as the reference year, because it is the latest year in the data.
- The train-test result depends on one random split; results change slightly with a different seed. Cross-validation could be used for a more stable estimate.
- Luxury cars with very high prices are real observations, so they are kept, but they strongly influence the raw-price models.
- The analysis is observational: coefficients describe associations in this dataset, not causal effects.
