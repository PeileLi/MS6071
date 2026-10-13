library(tidyverse)

cars <- read_csv("archive/Dataset.csv")

cars_clean <- cars |>
  select(
    price,
    `distance_travelled(kms)`,
    year,
    car_age,
    brand,
    fuel_type
  ) |>
  filter(
    !is.na(price),
    !is.na(`distance_travelled(kms)`),
    price > 0,
    `distance_travelled(kms)` >= 0
  )

glimpse(cars_clean)
summary(cars_clean)

price_limit <- quantile(cars_clean$price, 0.95)

ggplot(cars_clean, aes(x = price)) +
  geom_histogram(
    bins = 30,
    fill = "steelblue",
    color = "white"
  ) +
  coord_cartesian(xlim = c(0, price_limit)) +
  scale_x_continuous(labels = label_comma()) +
  labs(
    title = "Distribution of Used Car Prices",
    x = "Car Price",
    y = "Number of Cars"
  ) +
  theme_minimal()



cars_plot <- cars_clean |>
  filter(
    `distance_travelled(kms)` <= 150000,
    price <= quantile(cars_clean$price, 0.95)
  )

ggplot(
  cars_plot,
  aes(x = `distance_travelled(kms)`, y = price)
) +
  geom_point(alpha = 0.3, size = 1.5) +
  geom_smooth(method = "lm", se = FALSE, color = "red") +
  scale_x_continuous(
    breaks = seq(0, 150000, 25000),
    labels = scales::label_comma()
  ) +
  scale_y_continuous(
    labels = scales::label_comma()
  ) +
  labs(
    title = "Mileage vs Used Car Price",
    subtitle = "Cars with mileage up to 150,000 km and prices below the 95th percentile",
    x = "Distance Travelled (km)",
    y = "Car Price"
  ) +
  theme_minimal()


model <- lm(
  price ~ `distance_travelled(kms)`,
  data = cars_clean
)

summary(model)


model2 <- lm(
  price ~ `distance_travelled(kms)` + car_age,
  data = cars_clean
)

summary(model2)


summary(model)$r.squared
summary(model2)$r.squared

model_comparison <- tibble(
  Model = c("Model 1", "Model 2"),
  R_squared = c(
    summary(model)$r.squared,
    summary(model2)$r.squared
  ),
  Adjusted_R_squared = c(
    summary(model)$adj.r.squared,
    summary(model2)$adj.r.squared
  ),
  Residual_SE = c(
    summary(model)$sigma,
    summary(model2)$sigma
  )
)

model_comparison

