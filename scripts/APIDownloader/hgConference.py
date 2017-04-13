from APIDownloader import APIDownloader
from argparse import ArgumentParser
from pyspark import SparkContext, StorageLevel
from pyspark.sql import HiveContext
import json
from dateUtil import DateUtil

'''
spark-submit --deploy-mode client \
    --py-files /home/hadoop/effect-workflows/lib/python-lib.zip \
    hgConference.py \
    --outputFolder <HDFS or s3 output folder> \
    --team "hyperiongray" \
    --password <PASSWORD> \
'''

if __name__ == "__main__":

    sc = SparkContext()
    sqlContext = HiveContext(sc)

    parser = ArgumentParser()
    parser.add_argument("-f", "--outputFolder", type=str, help="Output foldername", required=True)
    parser.add_argument("-t", "--team", type=str, help="Team Name", required=True)
    parser.add_argument("-d", "--date", type=str, help="Greater than equal date", required=True)
    parser.add_argument("-p", "--password", type=str, help="password for connecting to hyperion gray api", required=True)

    args = parser.parse_args()
    print ("Got arguments:", args)

    #url_cpe = "https://effect.hyperiongray.com/api/cpe/"
    if(args.date == "1970-01-01T00:00:00Z"):
        url_conference = "https://effect.hyperiongray.com/api/conference" #To get everything
    else:
        url_conference = "https://effect.hyperiongray.com/api/conference/updates/" + str(args.date)

    apiDownloader = APIDownloader(sc, sqlContext)

    results = apiDownloader.download_api(url_conference, "isi", args.password)
    if results is not None:
        print "Downloaded ", len(results), " new conference data rows. Adding them to CDR"
        if len(results) > 0:
            rdd = sc.parallelize(results)
            rdd.map(lambda x: ("hg-conference", json.dumps(x))).saveAsSequenceFile(args.outputFolder + "/hg-conference")
            apiDownloader.load_into_cdr(results, "hg_conference", args.team, "hg-conference")
