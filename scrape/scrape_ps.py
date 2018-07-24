import sys
import requests
import time
import random
import csv
import os.path
from bs4 import BeautifulSoup

def write_result(res, name, dir = "ps_geo/"):
    with open(dir + name + ".html", "wb") as f:
        f.write(res.text.encode('utf-8'))

def download_url(url, name, dir):
    res = session.get(url)
    if res.status_code != 200:
        time.sleep(2)
        res = session.get(url)
        if res.status_code != 200:
            return "fail"

    write_result(res, name, dir)

    return res

def download_cons(prov, const, consttype):
    url = "https://www.ecp.gov.pk//frmPSGEGE.aspx?ProvCode=%s&ConstCode=%s&ElectionType=%s" % (prov, const, consttype)
    name = "_".join([prov, const, consttype])

    if not os.path.isfile("cons/" + name + ".html"):
        res = download_url(url, name, "cons/")
        if res == "fail":
            print name
            sys.exit(2)
        else:
            out = res.text
    else:
        with open("cons/" + name + ".html", "r") as f:
            out = f.read()
    return(out)


session = requests.Session()
#s.headers.update(headers)

    
provs = {'11': 297, '13': 51, '12': 130, '9': 99}
fails = []
img_url = "https://www.ecp.gov.pk"
dat = []
for prov, max_cons in provs.iteritems():
    for i in range(max_cons):
        print("cons: ", str(i+1))
        cons = download_cons(prov, str(i + 1), "PA")
        soup = BeautifulSoup(cons)
        rows = soup.find("table", attrs={'style':'font-family:Arial, Helvetica, sans-serif'}).find_all("tr")
        first = True
        for row in rows:
            cols = row.find_all("td")
            if len(cols) == 13:
                if first:
                    first = False
                else:
                    img_full = img_url + cols[12].find("a")['href'].encode('utf-8')
                    dat.append([prov, str(i+1), 'PA'] + [col.text.encode('utf-8') for col in cols[0:11]] + [img_full])
naprovs = {'9': range(1, 40), '10': range(40, 52), '14': range(52, 55), '11': range(55, 196), '12': range(196, 257), '13': range(257, 273)}
for prov, consr in naprovs.iteritems():
    for i in consr:
        print("cons: ", str(i))
        cons = download_cons(prov, str(i), "NA")
        soup = BeautifulSoup(cons)
        rows = soup.find("table", attrs={'style':'font-family:Arial, Helvetica, sans-serif'}).find_all("tr")
        first = True
        for row in rows:
            cols = row.find_all("td")
            if len(cols) == 13:
                if first:
                    first = False
                else:
                    img_full = img_url + cols[12].find("a")['href'].encode('utf-8')
                    dat.append([prov, str(i), 'NA'] + [col.text.encode('utf-8') for col in cols[0:11]] + [img_full])

names = ['prov_number', 'cons_number', 'cons_type', 'ps_number', 'ps_number', 'ps_name', 'male_booths', 'female_booths', 'total_booths', 'male_votes', 'female_voters', 'total_votes', 'lat', 'long', 'photo_url']
with open("scraped_ps_data.csv",'wb') as of:
    wr = csv.writer(of)
    wr.writerow(names)
    wr.writerows(dat)

