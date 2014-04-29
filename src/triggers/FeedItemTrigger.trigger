trigger FeedItemTrigger on FeedItem (after insert) {
    
    if (Trigger.isAfter && Trigger.isInsert) {
        
        List<String> opportunityIds = new List<String>();
        List<String> feedBodies = new List<String>();
        List<String> feedItemIds = new List<String>();
        
        for (FeedItem feed: trigger.new)
        {
            opportunityIds.add(feed.parentId);
            feedBodies.add(feed.Body);
            feedItemIds.add(feed.Id);
        }
        CAREforceUtility.createCAREforceCase(opportunityIds, feedBodies, feedItemIds);
    }
}