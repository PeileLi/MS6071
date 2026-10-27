library(tidyverse)
library(broom)
library(scales)

csv_path <- "C:/Users/a2871/OneDrive - University of Limerick/Year5/MS6071/Car details v3.csv"

# Output folders
dir.create("plots",  showWarnings = FALSE)
dir.create("output", showWarnings = FALSE)
save_plot <- function(name, w = 8, h = 5, plot = ggplot2::last_plot())
  ggsave(file.path("plots", name), plot = plot, width = w, height = h, dpi = 200)

theme_set(theme_minimal(base_size = 13))

# Part 1 - Data import and inspection
cars <- read_csv(csv_path, show_col_types = FALSE)

head(cars)
dim(cars)                 # rows and columns
names(cars)               # variable names
glimpse(cars)             # variable types
colSums(is.na(cars))      # missing values per column


# Part 2 - Data cleaning

# 2.1 Convert specification columns to numeric.
cars <- cars %>%
  mutate(
    mileage_num = na_if(suppressWarnings(parse_number(mileage)), 0),   # km/l or km/kg
    engine_num  = na_if(suppressWarnings(parse_number(engine)), 0),    # CC
    power_num   = na_if(suppressWarnings(parse_number(max_power)), 0)  # bhp
  )
colSums(is.na(cars[c("mileage_num", "engine_num", "power_num")]))

# 2.2 Duplicates
n_duplicates <- sum(duplicated(cars))
cat("Exact duplicate rows:", n_duplicates, "of", nrow(cars), "\n")
cars_dedup <- cars %>% distinct()
cat("Rows after removing duplicates:", nrow(cars_dedup), "\n")

# 2.3 Implausible values
cat("Missing price/km/year:",
    sum(is.na(cars_dedup$selling_price) | is.na(cars_dedup$km_driven) | is.na(cars_dedup$year)), "\n")
cat("Price <= 0:",          sum(cars_dedup$selling_price <= 0, na.rm = TRUE), "\n")
cat("Distance <= 0:",       sum(cars_dedup$km_driven <= 0, na.rm = TRUE), "\n")
cat("Distance > 300,000 km:", sum(cars_dedup$km_driven > 300000, na.rm = TRUE), "\n")
cat("Year outside 1983-2020:", sum(cars_dedup$year < 1983 | cars_dedup$year > 2020, na.rm = TRUE), "\n")

# 2.4 Filter and create car age.
cars_model <- cars_dedup %>%
  filter(
    !is.na(selling_price), !is.na(km_driven), !is.na(year),
    selling_price > 0,
    km_driven > 0, km_driven <= 300000,
    year >= 1983, year <= 2020
  ) %>%
  mutate(car_age = 2020 - year)   # latest year in the data is 2020

cat("Rows used for modelling:", nrow(cars_model), "\n")

# Part 3 - Descriptive statistics

summary(cars_model[c("selling_price", "km_driven", "car_age")])

desc_stats <- cars_model %>%
  select(selling_price, km_driven, car_age) %>%
  pivot_longer(everything(), names_to = "variable") %>%
  group_by(variable) %>%
  summarise(
    n      = n(),
    mean   = mean(value),
    median = median(value),
    sd     = sd(value),
    min    = min(value),
    max    = max(value),
    .groups = "drop"
  )
print(desc_stats)


# Part 4 - Exploratory data analysis


# 4.1 Price distribution: raw vs log (shows why a log transformation helps)
p_raw <- ggplot(cars_model, aes(selling_price)) +
  geom_histogram(bins = 40, fill = "steelblue") +
  scale_x_continuous(labels = label_comma()) +
  coord_cartesian(xlim = c(0, 2000000)) +
  labs(title = "Raw price: heavily right-skewed",
       x = "Selling Price (₹)", y = "Number of Cars")

p_log <- ggplot(cars_model, aes(selling_price)) +
  geom_histogram(bins = 40, fill = "darkorange") +
  scale_x_log10(labels = label_comma()) +
  labs(title = "Log price: close to symmetric",
       x = "Selling Price (₹, log scale)", y = "Number of Cars")

if (requireNamespace("patchwork", quietly = TRUE)) {
  p_dist <- patchwork::wrap_plots(p_raw, p_log)
  print(p_dist)
  save_plot("01_price_distribution.png", 12, 5, plot = p_dist)
} else {
  print(p_raw); print(p_log)
  save_plot("01_price_distribution.png", plot = p_raw)
}

# 4.2 Selling price vs distance driven
ggplot(cars_model, aes(km_driven, selling_price)) +
  geom_point(alpha = 0.3) +
  geom_smooth(method = "lm", se = FALSE, color = "red") +
  scale_x_continuous(labels = label_comma()) +
  scale_y_continuous(labels = label_comma()) +
  coord_cartesian(ylim = c(0, 2000000)) +
  labs(title = "Selling Price vs Distance Travelled",
       x = "Distance Travelled (km)", y = "Selling Price (₹)")
save_plot("02_price_vs_km.png")

# 4.3 Selling price vs car age (raw scale, then log axis)
ggplot(cars_model, aes(car_age, selling_price)) +
  geom_jitter(width = 0.2, alpha = 0.25) +
  geom_smooth(method = "lm", se = FALSE, color = "red") +
  scale_y_continuous(labels = label_comma()) +
  coord_cartesian(ylim = c(0, 2000000)) +
  labs(title = "Selling Price vs Car Age",
       x = "Car age (years)", y = "Selling Price (₹)")
save_plot("03_price_vs_age.png")

ggplot(cars_model, aes(car_age, selling_price)) +
  geom_jitter(width = 0.2, alpha = 0.25) +
  geom_smooth(method = "lm", se = FALSE, color = "red") +
  scale_y_log10(labels = label_comma()) +
  labs(title = "Selling Price vs Car Age (log price axis)",
       subtitle = "On the log scale the relationship is close to linear",
       x = "Car age (years)", y = "Selling Price (₹, log scale)")
save_plot("04_price_vs_age_log.png")

# 4.4 Selling price vs fuel efficiency
ggplot(cars_model, aes(mileage_num, selling_price)) +
  geom_point(alpha = 0.3) +
  scale_y_continuous(labels = label_comma()) +
  coord_cartesian(ylim = c(0, 2000000)) +
  labs(title = "Selling Price vs Fuel Efficiency",
       x = "Fuel Efficiency (km/litre or km/kg)", y = "Selling Price (₹)")
save_plot("05_price_vs_efficiency.png")


# Part 5 - Model 1: simple linear regression

model1 <- lm(selling_price ~ km_driven, data = cars_model)
summary(model1)
confint(model1)

# Part 6 - Model 2: multiple linear regression
model2 <- lm(selling_price ~ km_driven + car_age, data = cars_model)
summary(model2)
confint(model2)

# F-test for nested models
anova(model1, model2)

# Part 7 - Model comparison and validation

# 7.1 In-sample comparison
model_comparison <- tibble(
  Model         = c("Model 1: km", "Model 2: km + age"),
  R_squared     = c(summary(model1)$r.squared,     summary(model2)$r.squared),
  Adj_R_squared = c(summary(model1)$adj.r.squared, summary(model2)$adj.r.squared),
  Residual_SE   = c(summary(model1)$sigma,         summary(model2)$sigma),
  AIC           = c(AIC(model1), AIC(model2)),
  BIC           = c(BIC(model1), BIC(model2))
)
print(model_comparison)

# 7.2 Out-of-sample validation: 80/20 train-test split
rmse <- function(actual, pred) sqrt(mean((actual - pred)^2))
mae  <- function(actual, pred) mean(abs(actual - pred))

set.seed(123)
train_idx <- sample(nrow(cars_model), size = round(0.8 * nrow(cars_model)))
train <- cars_model[train_idx, ]
test  <- cars_model[-train_idx, ]
cat("Training rows:", nrow(train), " Test rows:", nrow(test), "\n")

m1_train <- lm(selling_price ~ km_driven, data = train)
m2_train <- lm(selling_price ~ km_driven + car_age, data = train)

test_errors <- tibble(
  Model = c("Model 1: km", "Model 2: km + age"),
  Test_RMSE = c(rmse(test$selling_price, predict(m1_train, test)),
                rmse(test$selling_price, predict(m2_train, test))),
  Test_MAE  = c(mae(test$selling_price, predict(m1_train, test)),
                mae(test$selling_price, predict(m2_train, test)))
)
print(test_errors)


# Part 8 - Regression diagnostics and results output


# 8.1 Standard diagnostic plots: residuals vs fitted (linearity, constant variance),
#     Q-Q (normality), scale-location (constant variance), residuals vs leverage (influence)
par(mfrow = c(2, 2))
plot(model2)
par(mfrow = c(1, 1))

# 8.2 Constant variance test (Breusch-Pagan) - needs the lmtest package
if (requireNamespace("lmtest", quietly = TRUE)) print(lmtest::bptest(model2))

# 8.3 Collinearity (VIF) - needs the car package
if (requireNamespace("car", quietly = TRUE)) print(car::vif(model2))

# 8.4 Influential observations (Cook's distance > 4/n)
cooks_threshold <- 4 / nrow(cars_model)
influential <- cars_model %>%
  mutate(cooks_d     = cooks.distance(model2),
         leverage    = hatvalues(model2),
         std_residual = rstandard(model2)) %>%
  filter(cooks_d > cooks_threshold) %>%
  arrange(desc(cooks_d))

cat("Observations with Cook's D >", round(cooks_threshold, 5), ":", nrow(influential), "\n")
print(influential %>%
        select(name, year, km_driven, selling_price, cooks_d, leverage, std_residual) %>%
        slice_head(n = 10))

# 8.5 Save final results
coef_model2 <- tidy(model2, conf.int = TRUE)
print(coef_model2)

write_csv(desc_stats,        "output/descriptive_statistics.csv")
write_csv(model_comparison,  "output/model_comparison.csv")
write_csv(test_errors,       "output/test_errors.csv")
write_csv(coef_model2,       "output/model2_coefficients.csv")
write_csv(influential %>% select(name, year, km_driven, selling_price, cooks_d, leverage, std_residual),
          "output/influential_observations.csv")


# Sample for the extension: needs power, and only Diesel/Petrol (too few CNG/LPG)
cars_ext <- cars_model %>%
  filter(!is.na(power_num), fuel %in% c("Diesel", "Petrol")) %>%
  mutate(
    km_10k       = km_driven / 10000,   # unit: 10,000 km
    power_10     = power_num / 10,      # unit: 10 bhp
    log_price    = log(selling_price),
    transmission = factor(transmission, levels = c("Manual", "Automatic")),
    fuel         = factor(fuel, levels = c("Diesel", "Petrol"))
  )
cat("Rows in extension sample:", nrow(cars_ext), "\n")

# Models fitted on the same extension sample so they are comparable
ext_model2 <- lm(selling_price ~ km_driven + car_age, data = cars_ext)
model3 <- lm(log_price ~ km_10k + car_age, data = cars_ext)
model4 <- lm(log_price ~ km_10k + car_age + power_10 + transmission + fuel, data = cars_ext)
summary(model3)
summary(model4)

# Test-set comparison on a common split (log models are back-transformed to rupees)
set.seed(123)
ext_idx   <- sample(nrow(cars_ext), size = round(0.8 * nrow(cars_ext)))
ext_train <- cars_ext[ext_idx, ]
ext_test  <- cars_ext[-ext_idx, ]

eval_split <- function(label, formula, log_resp) {
  m <- lm(formula, data = ext_train)
  p <- predict(m, ext_test)
  if (log_resp) p <- exp(p)
  tibble(Model = label,
         R_squared_train = summary(m)$r.squared,
         Test_RMSE = rmse(ext_test$selling_price, p),
         Test_MAE  = mae(ext_test$selling_price, p))
}

ext_comparison <- bind_rows(
  eval_split("Model 2: km + age (raw price)", selling_price ~ km_driven + car_age, FALSE),
  eval_split("Model 3: log(price) ~ km + age", log_price ~ km_10k + car_age, TRUE),
  eval_split("Model 4: log(price) ~ km + age + power + transmission + fuel",
             log_price ~ km_10k + car_age + power_10 + transmission + fuel, TRUE)
)
print(ext_comparison)
write_csv(ext_comparison, "output/extension_model_comparison.csv")
# AIC is comparable only within the same response variable
AIC(model3, model4)

# E.1 Distance vs price: coloured by car age group, faceted by fuel type
cars_ext <- cars_ext %>%
  mutate(age_group = cut(car_age, c(-1, 3, 7, 12, 40),
                         labels = c("0-3 yrs", "4-7 yrs", "8-12 yrs", "13+ yrs")))

ggplot(cars_ext, aes(km_driven, selling_price, color = age_group)) +
  geom_point(alpha = 0.2) +
  geom_smooth(method = "lm", se = FALSE) +
  facet_wrap(~ fuel) +
  # x axis: distance in thousand km, one tick every 50,000 km
  scale_x_continuous(breaks = seq(0, 300000, 50000),
                     labels = label_number(scale = 1e-3, suffix = "k")) +
  # y axis: price on a log scale with denser ticks, in lakh (1 lakh = 100,000 rupees)
  scale_y_log10(breaks = c(5e4, 1e5, 2e5, 5e5, 1e6, 2e6, 5e6, 1e7),
                labels = label_number(scale = 1e-5, accuracy = 0.1, drop0trailing = TRUE),
                minor_breaks = NULL) +
  labs(title = "Distance vs price, by car age group and fuel type",
       subtitle = "Once fuel type is separated, distance lowers price clearly for newer cars and little for older ones",
       x = "Distance Travelled (thousand km)",
       y = "Selling Price (₹ lakh, log scale)",
       color = "Car age")
save_plot("E1_km_price_by_age_fuel.png", 11, 5.5)

# E.2 Coefficient plot: % effect of each variable on price (easiest to explain)
coef_tbl <- tidy(model4, conf.int = TRUE) %>%
  filter(term != "(Intercept)") %>%
  mutate(
    pct   = (exp(estimate) - 1) * 100,
    lo    = (exp(conf.low)  - 1) * 100,
    hi    = (exp(conf.high) - 1) * 100,
    label = dplyr::recode(term,
                          km_10k = "Per +10,000 km driven",
                          car_age = "Per +1 year of age",
                          power_10 = "Per +10 bhp power",
                          transmissionAutomatic = "Automatic (vs Manual)",
                          fuelPetrol = "Petrol (vs Diesel)")
  )
print(coef_tbl %>% select(label, pct, lo, hi))
write_csv(coef_tbl %>% select(label, pct, lo, hi), "output/model4_percent_effects.csv")

ggplot(coef_tbl, aes(pct, reorder(label, pct))) +
  geom_vline(xintercept = 0, linetype = "dashed") +
  geom_pointrange(aes(xmin = lo, xmax = hi), color = "steelblue") +
  labs(title = "What drives used-car prices? (Model 4)",
       subtitle = "Estimated % change in selling price, holding other variables fixed (95% CI)",
       x = "% change in price", y = NULL)
save_plot("E2_coefficients.png", 9, 4.5)

# E.3 Prediction curves: predicted price by car age and distance level
grid <- expand_grid(
  car_age      = 0:15,
  km_10k       = c(2.5, 6, 12),
  power_10     = median(cars_ext$power_10),
  transmission = factor("Manual", levels = levels(cars_ext$transmission)),
  fuel         = factor("Diesel", levels = levels(cars_ext$fuel))
)
pred <- predict(model4, grid, interval = "confidence")
grid <- bind_cols(grid, as_tibble(pred)) %>%
  mutate(across(c(fit, lwr, upr), exp),
         km_label = factor(paste0(km_10k * 10, ",000 km"),
                           levels = paste0(c(25, 60, 120), ",000 km")))

ggplot(grid, aes(car_age, fit, color = km_label, fill = km_label)) +
  geom_ribbon(aes(ymin = lwr, ymax = upr), alpha = 0.15, color = NA) +
  geom_line(linewidth = 1.1) +
  scale_y_continuous(labels = label_comma()) +
  labs(title = "Predicted price by car age and distance driven",
       subtitle = "Manual diesel car with median engine power",
       x = "Car age (years)", y = "Predicted Selling Price (₹)",
       color = "Distance", fill = "Distance")
save_plot("E3_predicted_curves.png")

# E.4 Actual vs predicted values
cars_ext$pred_price <- exp(fitted(model4))

ggplot(cars_ext, aes(pred_price, selling_price)) +
  geom_point(alpha = 0.25) +
  geom_abline(slope = 1, intercept = 0, color = "red", linewidth = 1) +
  scale_x_log10(labels = label_comma()) +
  scale_y_log10(labels = label_comma()) +
  labs(title = "Actual vs predicted price (Model 4)",
       subtitle = sprintf("R-squared = %.2f on log price; points on the red line = perfect prediction",
                          summary(model4)$r.squared),
       x = "Predicted Price (₹, log scale)", y = "Actual Price (₹, log scale)")
save_plot("E4_actual_vs_predicted.png")

# E.5 Diagnostics for the log model and collinearity check
par(mfrow = c(2, 2))
plot(model4)
par(mfrow = c(1, 1))
if (requireNamespace("car", quietly = TRUE)) print(car::vif(model4))