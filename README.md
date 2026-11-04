<<<<<<< HEAD

=======
>>>>>>> a8ca162 (.)
## Analysis Overview

### Part 1: Data Import and Inspection
Reads the CSV and inspects its structure: number of rows and columns, variable names, data types, and missing values per column.
**Functions:** `read_csv()`, `dim()`, `names()`, `glimpse()`, `colSums(is.na())`

### Part 2: Data Cleaning
- Converts text specification columns (`mileage`, `engine`, `max_power`) to numeric. Values recorded as `0` or a bare unit are treated as missing.
- Detects and removes exact duplicate rows.
- Reports implausible values before filtering (non-positive price or distance, distances above 300,000 km, years outside 1983 to 2020).
- Filters the data and creates two variables: `car_age = 2020 - year`, and `km_10k = km_driven / 10000` (distance in units of 10,000 km, used in all four models so that coefficients are directly comparable).

| Step | Rows |
|---|---|
| Raw data | 8,128 |
| After removing 1,202 exact duplicates | 6,926 |
| After filtering (modelling sample) | 6,908 |
| Extension sample (power known, Diesel or Petrol only) | 6,613 |

**Functions:** `mutate()`, `filter()`, `distinct()`

### Part 3: Descriptive Statistics
Computes the mean, median, standard deviation, minimum, and maximum of `selling_price`, `km_driven`, and `car_age`.
**Functions:** `summary()`, `summarise()`, `mean()`, `median()`
**Output:** `output/descriptive_statistics.csv`

### Part 4: Exploratory Data Analysis
- Price distribution on the raw and log scales, which shows the strong right skew of price.
- Selling price versus distance driven, with a fitted line.
- Selling price versus car age, on the raw scale and with a log price axis.
- Selling price versus fuel efficiency (cars with missing efficiency are dropped from this plot, which causes a harmless R warning).

**Functions:** `ggplot()`, `geom_histogram()`, `geom_point()`, `geom_smooth()`
**Output:** `plots/01_` to `plots/05_`

### Part 5: Model 1, Simple Linear Regression
The baseline model: `selling_price ~ km_10k`. Reports coefficients, confidence intervals, and R².

### Part 6: Model 2, Multiple Linear Regression
Adds car age: `selling_price ~ km_10k + car_age`. An F-test (`anova(model1, model2)`) checks whether the extra variable significantly improves the fit.

A sanity check refits Model 2 with distance in km instead of 10,000 km. It shows that rescaling a predictor only changes the size of its coefficient: fitted values, t-values, p-values, and R² are identical.

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

### Extension: Log-Price Models
Raw price is highly skewed and its relationship with car age is curved, so the extension models the logarithm of price.

- **Model 3:** `log(price) ~ km_10k + car_age` (same variables as Model 2, with log price)
- **Model 4:** `log(price) ~ km_10k + car_age + power_10 + transmission + fuel` (`power_10` is engine power in units of 10 bhp)
- Uses the extension sample of 6,613 cars. Models 2, 3, and 4 are compared on a common train-test split, with log predictions converted back to rupees using `exp()`. AIC is compared only between Models 3 and 4, because they share the same response variable.
- Figures: **E1** distance versus price by car age group and fuel type, **E2** coefficient plot showing the percentage effect of each variable on price, **E3** predicted price curves, **E4** actual versus predicted prices, and **E5** diagnostics and VIF for Model 4.

**Output:** `plots/E1_` to `plots/E4_`, `output/extension_model_comparison.csv`, `output/model4_percent_effects.csv`

## Key Results

### Core models (6,908 cars)

| Model | R² | Test RMSE (₹) | Test MAE (₹) |
|---|---|---|---|
| Model 1: km | 0.044 | 457,793 | 275,965 |
| Model 2: km + age | 0.188 | 416,565 | 224,836 |

- Adding car age significantly improves the model (F = 1226.8, p < 2.2e-16).
- In Model 2, each extra year of age is associated with about ₹54,461 lower price. Distance is not significant (about ₹1,563 lower per 10,000 km, p = 0.259), whereas in Model 1 it is (about ₹23,690 lower per 10,000 km). Distance therefore mostly acts as a proxy for age.
- Diagnostics show heteroscedasticity (Breusch-Pagan p < 2.2e-16) and 206 influential observations, mostly luxury cars with very high prices. VIF is about 1.26, so collinearity is not a concern. These results motivate the log-price extension.

### Extension (6,613 cars, common train-test split)

| Model | Train R² | Test RMSE (₹) | Test MAE (₹) |
|---|---|---|---|
| Model 2: km + age (raw price) | 0.177 | 432,133 | 236,568 |
| Model 3: log(price), km + age | 0.514 | 438,998 | 212,970 |
| Model 4: log(price), km + age + power + transmission + fuel | 0.824 | 184,209 | 112,642 |

- Model 4 explains about 83% of the variation in log price. Its effects, holding the other variables fixed: about 10.9% lower price per extra year of age, 12.0% higher per extra 10 bhp, 16.5% higher for automatic versus manual, 23.4% lower for petrol versus diesel, and only 0.5% lower per extra 10,000 km.
- The distance coefficient is positive in Model 3 but negative in Model 4. This is confounding: high-mileage cars are more often powerful diesels, which cost more.
- Model 3 has a slightly higher test RMSE than Model 2 but a lower MAE, because converting log predictions back to rupees underestimates a few very expensive cars.

## Assumptions and Limitations

- Distances above 300,000 km are treated as outliers and excluded. Change the filter in Part 2.4 if a different rule is required.
- Car age uses 2020 as the reference year, because it is the latest year in the data.
- Only exact duplicate rows are removed; repeated listings of the same car with small differences may remain.
- The train-test result depends on one random split; results change slightly with a different seed. Cross-validation could be used for a more stable estimate.
- Luxury cars with very high prices are real observations, so they are kept, but they strongly influence the raw-price models.
- Converting log predictions back to rupees with `exp()` slightly underestimates expensive cars.
- Brand and condition are not in the models, so individual prices still vary a lot.
- The analysis is observational: coefficients describe associations in this dataset, not causal effects.
