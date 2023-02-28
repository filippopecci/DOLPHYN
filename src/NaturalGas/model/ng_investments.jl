function ng_investments!(EP,inputs,setup)

    SV = inputs["StorageVaporFacilities"]; #Index set of LNG storage and varporization facilities
    LIQ = inputs["LiquefactionFacilities"]; #Index set of liquefaction facilities

    @expression(EP, eNgExistingCap[y in 1:G], dfLNG[y,:Existing_Cap_MW])

end