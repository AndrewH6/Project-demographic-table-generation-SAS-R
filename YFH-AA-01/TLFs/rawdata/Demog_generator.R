#install.packages("writexl")
library(writexl)



Demog_generator <- function(n = 500){
  
  gender_v <- c("MALE","FEMALE")
  GENDER <- sample(gender_v, n, replace = TRUE)
  
  race_v <- c("WHITE","BLACK","HISPANIC",
              "ASIAN","NATIVE","OTHER")
  RACE <- sample(race_v, n, replace = TRUE)
  
  birthdtf <- sample(seq(as.Date('1930/01/01'), as.Date('2000/01/01'), by="day"), n)
  birthdtf <- gsub("-", "", birthdtf)
  
  subjid <- as.character((10000+1):(10000+n))
  
  treatment_v <- c(1,2)
  treatmnt <- sample(treatment_v, n, replace = TRUE)
  
  height <- sample(rnorm(300, mean = 175, sd = 15), n, replace = TRUE)
  hgtunit <- rep("cm", n)
  
  weight <- sample(rnorm(300, mean = 75, sd = 25), n, replace = TRUE)
  wtgUnit <- rep("kg", n)
  
  itt <- rep(1,n)
  itt[sample(1:n,round(0.05*n))] <- 0
  
  safety <- rep(1,n)
  safety[sample(1:n,round(0.05*n))] <- 0
  
  VISIT <- rep(0,n)
  
  result_data <- data.frame(VISIT,GENDER,RACE,birthdtf,subjid,treatmnt,height,
                            hgtunit,weight,wtgUnit,itt,safety)
  return(result_data)
}

Demog_data <- Demog_generator(n=2000)







write_xlsx(Demog_data,"Demog_data.xlsx", 
           col_names = TRUE)