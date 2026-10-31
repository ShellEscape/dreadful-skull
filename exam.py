num = int(input("Please input number of exams: "))
avg = 0
for i in range(num):
    score = int(input("Enter exam scorer: "))
    avg = (avg + score)
print("your average is: ", avg/num) 