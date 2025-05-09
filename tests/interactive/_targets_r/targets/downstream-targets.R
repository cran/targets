list(
  tar_target(data, raw_data %>% filter(!is.na(Ozone))),
  tar_target(hist, create_plot(data)),
  tar_target(fit, biglm(Ozone ~ Wind + Temp, data))
)
