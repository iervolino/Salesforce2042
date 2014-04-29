trigger StudentAttributesToBannerTrigger on StudentAttributesToBanner__c (after insert, after update) {
    // to push data/log after PowerCenter job Banner->SAToBaner->StudentAttributes
}