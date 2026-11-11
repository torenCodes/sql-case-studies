import sys, sqlite3, pandas as pd
src, dst = sys.argv[1], sys.argv[2]
keep = ['FlightDate','DayOfWeek','Reporting_Airline','Tail_Number','Flight_Number_Reporting_Airline',
 'Origin','OriginCityName','OriginState','Dest','DestCityName','DestState',
 'CRSDepTime','DepTime','DepDelay','DepDelayMinutes','DepDel15','DepTimeBlk','TaxiOut','WheelsOff',
 'WheelsOn','TaxiIn','CRSArrTime','ArrTime','ArrDelay','ArrDelayMinutes','ArrDel15',
 'Cancelled','CancellationCode','Diverted','CRSElapsedTime','ActualElapsedTime','AirTime','Distance',
 'CarrierDelay','WeatherDelay','NASDelay','SecurityDelay','LateAircraftDelay']
dtype = {'Tail_Number':str,'CRSDepTime':str,'DepTime':str,'CRSArrTime':str,'ArrTime':str,'WheelsOff':str,'WheelsOn':str,'CancellationCode':str,'Flight_Number_Reporting_Airline':str}
df = pd.read_csv(src, usecols=keep, dtype=dtype, low_memory=False)
con = sqlite3.connect(dst)
df.to_sql('flights', con, if_exists='replace', index=False, chunksize=50000)
con.execute('CREATE INDEX ix_tail_date ON flights(Tail_Number, FlightDate)')
con.execute('CREATE INDEX ix_origin ON flights(Origin)')
con.commit(); print(len(df), 'rows')
