trigger FeedCommentTrigger on FeedComment (after insert) {
    
    if (Trigger.isAfter && Trigger.isInsert) {
        
        List<String> opportunityIds = new List<String>();
        List<String> feedBodies = new List<String>();
        List<String> feedItemIds = new List<String>();
        
        for (FeedComment feed: trigger.new)
        {
            opportunityIds.add(feed.parentId);
            feedBodies.add(feed.commentBody);
            feedItemIds.add (feed.FeedItemId);
        }
        CAREforceUtility.createCAREforceCase(opportunityIds, feedBodies, feedItemIds);
    }
}