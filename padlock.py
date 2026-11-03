from re import A
import pylint.test.regrtest_data.meta

import time
import calendar
def pygame():
    pygame().time.get_time()

# smart lock for door!

#please input a passcode! Four digit OR Five digits
passcode_five_digit = int(input())
passcode_five_digit_DIGITS = int(input())
four_digit_passcode = int(input())
four_digit_passcode_DIGITS = int(input())

 
# Explanation 1: Five digit passcode must be NUMBERS AND SPECIAL CHARACTERS ONLY. Including !,@,#,$,%,^,&,*,(,),_,-,+,=. 
# ALSO Can NOT end with a period. Due to secuirty purposes and or reasons. 
# Explanation 2: Same thing goes for FOUR DIGIT PASSCODES. They Also can and MUST include Numbers and Special characters ONLY. 
# ensure you also put a stop / break at the end bar of it all



if passcode_five_digit == 5:
    if passcode_five_digit_DIGITS >= 5 and passcode_five_digit >= 5:
        print("Please input your five digits\n" + A)
        a = int
else:
    pass

if four_digit_passcode >= 4:
    if four_digit_passcode_DIGITS >= 4 and four_digit_passcode >= 4:
        print("Please input your four digits\n" + a)
        a = int

else:
    pass

print("UNLOCKED")


