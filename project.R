library(tidyverse)

# 1. Import the dataset
cars <- read_csv("C:/Users/a2871/OneDrive - University of Limerick/Year5/MS6071/Car details v3.csv")

# 2. Inspect the dataset
head(cars)
dim(cars)
names(cars)

# 3. Check missing values
colSums(is.na(cars))

# 4. Convert vehicle specifications to numeric values
cars$mileage_num <- as.numeric(
  sub(" kmpl| km/kg", "", cars$mileage)
)

cars$engine_num <- as.numeric(
  sub(" CC", "", cars$engine)
)

cars$power_num <- as.numeric(
  sub(" bhp", "", cars$max_power)
)

# 5. Check the cleaned variables
summary(cars$mileage_num)
summary(cars$engine_num)
summary(cars$power_num)

# 6. Check missing values after conversion
colSums(is.na(cars[c(
  "mileage_num",
  "engine_num",
  "power_num"
)]))

# 7. Load the plotting package
library(ggplot2)

# 8. Plot selling price against kilometres driven
ggplot(cars, aes(x = km_driven, y = selling_price)) +
  geom_point(alpha = 0.4) +
  scale_x_continuous(labels = scales::label_comma()) +
  scale_y_continuous(labels = scales::label_comma()) +
  coord_cartesian(
    xlim = c(0, 300000),
    ylim = c(0, 2000000)
  ) +
  labs(
    title = "Selling Price vs Distance Travelled",
    x = "Distance Travelled (km)",
    y = "Selling Price (₹)"
  ) +
  theme_minimal()

# 9. Plot selling price against fuel efficiency
ggplot(cars, aes(x = mileage_num, y = selling_price)) +
  geom_point(alpha = 0.4) +
  scale_y_continuous(labels = scales::label_comma()) +
  coord_cartesian(
    xlim = c(0, 35),
    ylim = c(0, 2000000)
  ) +
  labs(
    title = "Selling Price vs Fuel Efficiency",
    x = "Fuel Efficiency (km/litre or km/kg)",
    y = "Selling Price (₹)"
  ) +
  theme_minimal()

# 10. Examine the distribution of selling prices
ggplot(cars, aes(x = selling_price)) +
  geom_histogram(bins = 30) +
  scale_x_continuous(
    labels = scales::label_comma()
  ) +
  coord_cartesian(xlim = c(0, 2000000)) +
  labs(
    title = "Distribution of Used Car Selling Prices",
    x = "Selling Price (₹)",
    y = "Number of Cars"
  ) +
  theme_minimal()

# 11. Prepare the data for regression analysis
cars_model <- cars[
  !is.na(cars$selling_price) &
    !is.na(cars$km_driven) &
    !is.na(cars$year) &
    cars$selling_price > 0 &
    cars$km_driven >= 0 &
    cars$year >= 1983 &
    cars$year <= 2020,
]

cars_model$car_age <- 2020 - cars_model$year

summary(cars_model[, c(
  "selling_price",
  "km_driven",
  "car_age"
)])

# 12. Model 1: Price predicted by mileage

model1 <- lm(
  selling_price ~ km_driven,
  data = cars_model
)

summary(model1)

# 13. Model 2: Price predicted by mileage and car age

model2 <- lm(
  selling_price ~ km_driven + car_age,
  data = cars_model
)

summary(model2)


# 14. Compare the two models

model_comparison <- data.frame(
  Model = c("Model 1", "Model 2"),
  R_squared = c(
    summary(model1)$r.squared,
    summary(model2)$r.squared
  ),
  Adjusted_R_squared = c(
    summary(model1)$adj.r.squared,
    summary(model2)$adj.r.squared
  ),
  Residual_SE = c(
    summary(model1)$sigma,
    summary(model2)$sigma
  ),
  AIC = c(
    AIC(model1),
    AIC(model2)
  )
)

print(model_comparison)


# 15. Plot the regression line for mileage and price

ggplot(cars_model, aes(x = km_driven, y = selling_price)) +
  geom_point(alpha = 0.3) +
  geom_smooth(method = "lm", se = FALSE, color = "red") +
  scale_x_continuous(labels = scales::label_comma()) +
  scale_y_continuous(labels = scales::label_comma()) +
  coord_cartesian(
    xlim = c(0, 300000),
    ylim = c(0, 2000000)
  ) +
  labs(
    title = "Linear Regression: Mileage vs Selling Price",
    x = "Distance Travelled (km)",
    y = "Selling Price (₹)"
  ) +
  theme_minimal()


# 16. Check the regression model

par(mfrow = c(2, 2))
plot(model2)
par(mfrow = c(1, 1))
