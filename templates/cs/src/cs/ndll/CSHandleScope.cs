namespace cs.ndll
{
    struct CSHandleScope
    {
		internal static CSHandleScope Create()
        {
            CSHandleScope scope = new CSHandleScope();
            CSHandleContainer container = CSHandleContainer.GetCurrent();
            scope.handleIndex = container.handles.Count;
            scope.memoryListIndex = container.memoryList.Count;
            return scope;
        }

        internal void Destroy()
        {
            CSHandleContainer.GetCurrent().ResizeHandles(handleIndex, memoryListIndex);
        }
        
		private int handleIndex;
        private int memoryListIndex;
    };
}