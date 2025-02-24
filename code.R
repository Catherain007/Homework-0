knitr

install.packages("knitr")
library(knitr)



---
  title: "Final Grade Distribution"
output: pdf_document
---
  ```{r, echo=FALSE}
load(file="my_data.Rmd")
summary(grades)
```
```{r, echo=F}
n <- nrow(mtcars)
```
Here `r n` cars are compared