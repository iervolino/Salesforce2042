public class CourseSearchPaginator {
    
    public Integer pageNum { get; set; }
    public Integer totalPage { get; set; }
    public Integer totalResults { get; set; }
    public List<CourseSearchPager> pageList { get; set; }
    public Boolean showPrevious { get; set; }
    public Boolean showNext { get; set; }
    public Boolean isAll { get; set; }
    public List<CourseSearchPageItem> availablePageList { get; set; }
         
    public CourseSearchPaginator(List<CourseArticleDAO.CourseArticleStudentView> initialList, Integer pageSize) {
        if(initialList == null) {
            totalResults = 0;
        }
        else {
            totalResults = initialList.size();
        }
        totalPage = (Integer)Math.ceil((Double)totalResults / (Double)pageSize);
        pageNum = 1;
        isAll = (totalResults <= pageSize) ? true : false;
        updateAvailableOptions();
        generatePages(initialList, pageSize);
        
    }
     
    private void generatePages(List<CourseArticleDAO.CourseArticleStudentView> initialList, Integer pageSize) {
        pageList = new List<CourseSearchPager>();
        List<CourseArticleDAO.CourseArticleStudentView> tempList;
        Integer page = 0;
        for(integer i = 0; i < totalResults; i++) {
            if(i == 0 || Math.mod(i, pageSize) == 0) {
                page++;
                Integer pageStart = (page * pageSize) - pageSize + 1;
                Integer pageEnd = page * pageSize;
                if(pageEnd > totalResults) {
                    pageEnd = totalResults;
                }
                tempList = new List<CourseArticleDAO.CourseArticleStudentView>();
                pageList.add(new CourseSearchPager(page, tempList, pageStart, pageEnd));
            }
            tempList.add(initialList.get(i));
        }
    }
     
    public void updateAvailableOptions() {
        showPrevious = (pageNum == 1) ? false : true;
        showNext = (pageNum == totalPage) ? false : true;
        
        availablePageList = new List<CourseSearchPageItem>();
        if(pageNum == 1) {
            availablePageList.add(new CourseSearchPageItem(1, true));
            for(Integer i = 2; i <= 5 && i <= totalPage; i++) {
                availablePageList.add(new CourseSearchPageItem(i, false));
            }
        }
        else if(pageNum == 2) {
            availablePageList.add(new CourseSearchPageItem(1, false));
            availablePageList.add(new CourseSearchPageItem(2, true));
            for(Integer i = 3; i <= 5 && i <= totalPage; i++) {
                availablePageList.add(new CourseSearchPageItem(i, false));
            }
        }
        else if(pageNum == (totalPage - 1)) {
            Integer min = (pageNum - 3 < 1) ? 1 : pageNum - 3;
            for(Integer i = min; i < pageNum; i++) {
                availablePageList.add(new CourseSearchPageItem(i, false));
            }
            availablePageList.add(new CourseSearchPageItem(pageNum, true));
            availablePageList.add(new CourseSearchPageItem(pageNum + 1, false));
        }
        else if(pageNum == totalPage) {
            Integer min = (pageNum - 4 < 1) ? 1 : pageNum - 4;
            for(Integer i = min; i < pageNum; i++) {
                availablePageList.add(new CourseSearchPageItem(i, false));
            }
            availablePageList.add(new CourseSearchPageItem(pageNum, true));
        }
        else {
            for(Integer i = pageNum - 2; i <= pageNum + 2; i++) {
                boolean currentPage = i == pageNum ? true : false;
                availablePageList.add(new CourseSearchPageItem(i, currentPage));
            }
        }
    }
         
    /*public void previous() {
        pageNum--;
        updateAvailableOptions();
    }
     
    public void next() {
        pageNum++;
        updateAvailableOptions();
    }
    
    public void first() {
        pageNum = 1;
        updateAvailableOptions();
    }
     
    public void last() {
        pageNum = totalPage;
        updateAvailableOptions();
    }*/
    
    public void changePage() {
        String page = Apexpages.currentPage().getParameters().get('page');
        if(!String.isEmpty(page)) {
            pageNum = Integer.valueOf(page);
            updateAvailableOptions();
        }
    }
    
    public CourseSearchPager getCurrentPage() {
        if(pageList == null || pageList.isEmpty()) {
            return null;
        }
        return pageList.get(pageNum - 1);
    }
    
    public class CourseSearchPager {
        
        public Integer pageNum { get; set; }
        public List<CourseArticleDAO.CourseArticleStudentView> pageContentList { get; set; }
        public Integer pageStart { get; set; }
        public Integer pageEnd { get; set; }
         
        public CourseSearchPager(Integer pageNum, List<CourseArticleDAO.CourseArticleStudentView> pageContentList, Integer pageStart, Integer pageEnd) {
            this.pageNum = pageNum;
            this.pageContentList = pageContentList;
            this.pageStart = pageStart;
            this.pageEnd = pageEnd;
        }
        
    }
    
    public class CourseSearchPageItem {
        
        public Integer pageNum { get; set; }
        public Boolean currentPage { get; set; }
        
        public CourseSearchPageItem(Integer pageNum, Boolean currentPage) {
            this.pageNum = pageNum;
            this.currentPage = currentPage;
        }
        
    }
    
}