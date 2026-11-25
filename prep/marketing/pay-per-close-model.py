# Pay-per-close model for BFT Bangsar. All inputs are assumptions to check with Kelvin.
# RM130/week, no lock-in. 52 weeks / 12 months = RM563 a calendar month.
PRICE=130*52/12; RATE=0.15; FEE=PRICE*RATE
NEW_MONTHS=12; WB_MONTHS=6
CHURN_OURS=0.06    # monthly churn of members we bring
CHURN_BASE=0.05    # monthly churn of his existing base
ORGANIC=5          # walk-ins/referrals per month, not ours
START=140
def run(new_per_month, wb_per_month, months=18, label=""):
    cohorts=[]  # (start_month, count, paid_months)
    base=START; rows=[]
    for m in range(1,months+1):
        n=new_per_month(m); w=wb_per_month(m)
        cohorts.append([m,n,NEW_MONTHS]); cohorts.append([m,w,WB_MONTHS])
        income=0; ours_active=0
        for c in cohorts:
            age=m-c[0]
            alive=c[1]*((1-CHURN_OURS)**age)
            ours_active+=alive
            if age < c[2]: income+=alive*FEE
        base=base*(1-CHURN_BASE)+ORGANIC
        total=base+ours_active
        rows.append((m,n,w,round(ours_active),round(total),round(income)))
    print(label)
    print(" m  new  wb  ours_active  total_members  our_income_RM")
    for r in rows: print("%2d %4d %3d %12d %14d %14d"%r)
    print("18-month income: RM%d  vs fixed RM7,000x18=RM126,000"%sum(r[5] for r in rows))
    print()
    return rows
ramp=lambda m:[10,14,18][m-1] if m<=3 else 22
wb=lambda m:{1:15,2:15}.get(m,3)
r1=run(ramp,wb,label="Base case: 10->22 new/month, 30 win-backs in first 2 months then 3/month")
ramp2=lambda m:[15,20,25][m-1] if m<=3 else 30
r2=run(ramp2,wb,label="Strong case: conversion doubles, 30 new/month")
ramp3=lambda m:[6,8,10][m-1] if m<=3 else 12
wb3=lambda m:{1:8,2:8}.get(m,1)
r3=run(ramp3,wb3,label="Weak case: 12 new/month")
print("fee per member per month: RM%.0f; max per new member (12 mo): RM%.0f"%(FEE,FEE*12))
avg_paid=sum(FEE*(1-CHURN_OURS)**a for a in range(12)); print("expected per new member at 6%% churn: RM%.0f"%avg_paid)
