from __future__ import division
from types import *
from random import shuffle
import random
random.seed(7)


names = ['Alex', 'Cameron', 'Erin', 'Gyeom', 'Jackie', 'Kate', 'Kenny', 'Lauren', 'Neil', 'Nick', 'Robert', 'Siyang', 'Spencer', 'Susan', 'William', 'Winston', 'Roy']
dates = ['11-22-2016', '11-29-2016', '12-01-2016']

def chunkify(lst,n):
    return [ lst[i::n] for i in xrange(n) ]

def assign_students(names, dates, course, limit=6):

    ratio = len(names)//len(dates)
    remainder = len(names) % len(dates)

    # Quality Check Assertion Messages
    assert type(names) is ListType, "names are not a list: {}".format(names)
    assert type(dates) is ListType, "dates are not a list: {}".format(dates)
    assert ratio <= limit, "Overload Warning: >= {} students/date. Limit: {}. Increase limit or add dates.".format(ratio, limit)

    try:
        if not (limit//2)<=ratio: raise Exception( "Optimization Warning" )
    except:
        print("Optimization Warning: Remove dates or decrease limit to optimize.")
        pass

    # Randomize Order
    shuffle(names)

    groups = chunkify(names, len(dates))
    writer = open("{}_Presentations.txt".format(course), "w")
    writer.write("")
    for date, group in zip(dates, groups[::-1]):
        for name in group:
            assignment = "{} : {}".format(date, name)
            print(assignment)
            writer.write(assignment+'\n')

    writer.close()


assign_students(names, dates, "SOSC_13100")
