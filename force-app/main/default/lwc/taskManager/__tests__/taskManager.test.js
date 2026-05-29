import { createElement } from 'lwc';
import TaskManager from 'c/taskManager';
import getTasks from '@salesforce/apex/TaskManagerController.getTasks';
import createTask from '@salesforce/apex/TaskManagerController.createTask';
import updateTaskStatus from '@salesforce/apex/TaskManagerController.updateTaskStatus';
import deleteTask from '@salesforce/apex/TaskManagerController.deleteTask';
import { ShowToastEventName } from 'lightning/platformShowToastEvent';

// Mock Apex methods
jest.mock(
    '@salesforce/apex/TaskManagerController.getTasks',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/TaskManagerController.createTask',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/TaskManagerController.updateTaskStatus',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

jest.mock(
    '@salesforce/apex/TaskManagerController.deleteTask',
    () => {
        return {
            default: jest.fn()
        };
    },
    { virtual: true }
);

// Mock data
const MOCK_TASKS = [
    {
        Id: '00T1234567890ABC',
        Subject: 'Test Task 1',
        Status: 'Not Started',
        Priority: 'High',
        ActivityDate: '2026-06-01',
        IsClosed: false,
        CreatedDate: '2026-05-29T10:00:00.000Z'
    },
    {
        Id: '00T1234567890DEF',
        Subject: 'Test Task 2',
        Status: 'In Progress',
        Priority: 'Normal',
        ActivityDate: '2026-06-05',
        IsClosed: false,
        CreatedDate: '2026-05-29T11:00:00.000Z'
    }
];

const MOCK_ACCOUNT_ID = '0011234567890ABC';

describe('c-task-manager', () => {
    afterEach(() => {
        // Clear DOM after each test
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        // Reset mocks
        jest.clearAllMocks();
    });

    // Helper to wait for async DOM updates
    async function flushPromises() {
        return new Promise((resolve) => setTimeout(resolve, 0));
    }

    it('should render component with title', () => {
        const element = createElement('c-task-manager', {
            is: TaskManager
        });
        element.recordId = MOCK_ACCOUNT_ID;
        document.body.appendChild(element);

        const card = element.shadowRoot.querySelector('lightning-card');
        expect(card).not.toBeNull();
        expect(card.title).toBe('Quick Task Manager');
    });

    it('should display tasks when wire service returns data', async () => {
        getTasks.mockResolvedValue(MOCK_TASKS);

        const element = createElement('c-task-manager', {
            is: TaskManager
        });
        element.recordId = MOCK_ACCOUNT_ID;
        document.body.appendChild(element);

        await flushPromises();

        const taskItems = element.shadowRoot.querySelectorAll('.task-item');
        expect(taskItems.length).toBe(2);
    });

    it('should display empty state when no tasks', async () => {
        getTasks.mockResolvedValue([]);

        const element = createElement('c-task-manager', {
            is: TaskManager
        });
        element.recordId = MOCK_ACCOUNT_ID;
        document.body.appendChild(element);

        await flushPromises();

        const emptyState = element.shadowRoot.querySelector('.slds-text-align_center p');
        expect(emptyState).not.toBeNull();
        expect(emptyState.textContent).toContain('No tasks yet');
    });

    it('should create task when form is submitted', async () => {
        getTasks.mockResolvedValue([]);
        createTask.mockResolvedValue({
            Id: '00T1234567890GHI',
            Subject: 'New Task',
            Status: 'Not Started',
            Priority: 'Normal'
        });

        const element = createElement('c-task-manager', {
            is: TaskManager
        });
        element.recordId = MOCK_ACCOUNT_ID;
        document.body.appendChild(element);

        await flushPromises();

        // Fill in the form
        const subjectInput = element.shadowRoot.querySelector('lightning-input[data-field="subject"]');
        subjectInput.value = 'New Task';
        subjectInput.dispatchEvent(new CustomEvent('change', { detail: { value: 'New Task' } }));

        const createButton = element.shadowRoot.querySelector('lightning-button');
        createButton.click();

        await flushPromises();

        expect(createTask).toHaveBeenCalled();
    });

    it('should show error toast when creating task without subject', async () => {
        const element = createElement('c-task-manager', {
            is: TaskManager
        });
        element.recordId = MOCK_ACCOUNT_ID;
        document.body.appendChild(element);

        const toastHandler = jest.fn();
        element.addEventListener(ShowToastEventName, toastHandler);

        const createButton = element.shadowRoot.querySelector('lightning-button');
        createButton.click();

        await flushPromises();

        expect(toastHandler).toHaveBeenCalled();
        expect(createTask).not.toHaveBeenCalled();
    });

    it('should update task status when checkbox is toggled', async () => {
        getTasks.mockResolvedValue(MOCK_TASKS);
        updateTaskStatus.mockResolvedValue({
            ...MOCK_TASKS[0],
            Status: 'Completed',
            IsClosed: true
        });

        const element = createElement('c-task-manager', {
            is: TaskManager
        });
        element.recordId = MOCK_ACCOUNT_ID;
        document.body.appendChild(element);

        await flushPromises();

        const checkbox = element.shadowRoot.querySelector('lightning-input[type="checkbox"]');
        checkbox.checked = true;
        checkbox.dispatchEvent(new CustomEvent('change', { target: { checked: true } }));

        await flushPromises();

        expect(updateTaskStatus).toHaveBeenCalled();
    });

    it('should delete task when delete button is clicked', async () => {
        getTasks.mockResolvedValue(MOCK_TASKS);
        deleteTask.mockResolvedValue();

        // Mock window.confirm
        global.confirm = jest.fn(() => true);

        const element = createElement('c-task-manager', {
            is: TaskManager
        });
        element.recordId = MOCK_ACCOUNT_ID;
        document.body.appendChild(element);

        await flushPromises();

        const deleteButton = element.shadowRoot.querySelector('lightning-button-icon');
        deleteButton.click();

        await flushPromises();

        expect(deleteTask).toHaveBeenCalled();
        expect(global.confirm).toHaveBeenCalledWith('Are you sure you want to delete this task?');
    });

    it('should not delete task when user cancels confirmation', async () => {
        getTasks.mockResolvedValue(MOCK_TASKS);

        // Mock window.confirm to return false
        global.confirm = jest.fn(() => false);

        const element = createElement('c-task-manager', {
            is: TaskManager
        });
        element.recordId = MOCK_ACCOUNT_ID;
        document.body.appendChild(element);

        await flushPromises();

        const deleteButton = element.shadowRoot.querySelector('lightning-button-icon');
        deleteButton.click();

        await flushPromises();

        expect(deleteTask).not.toHaveBeenCalled();
    });

    it('should handle error when fetching tasks fails', async () => {
        getTasks.mockRejectedValue({
            body: { message: 'Error fetching tasks' }
        });

        const element = createElement('c-task-manager', {
            is: TaskManager
        });
        element.recordId = MOCK_ACCOUNT_ID;

        const toastHandler = jest.fn();
        element.addEventListener(ShowToastEventName, toastHandler);

        document.body.appendChild(element);

        await flushPromises();

        expect(toastHandler).toHaveBeenCalled();
    });

    it('should show loading spinner during async operations', async () => {
        getTasks.mockResolvedValue([]);
        createTask.mockImplementation(() => new Promise(resolve => setTimeout(resolve, 100)));

        const element = createElement('c-task-manager', {
            is: TaskManager
        });
        element.recordId = MOCK_ACCOUNT_ID;
        document.body.appendChild(element);

        await flushPromises();

        // Fill in the form
        const subjectInput = element.shadowRoot.querySelector('lightning-input[data-field="subject"]');
        subjectInput.value = 'New Task';
        subjectInput.dispatchEvent(new CustomEvent('change', { detail: { value: 'New Task' } }));

        const createButton = element.shadowRoot.querySelector('lightning-button');
        createButton.click();

        // Check for spinner immediately after click
        const spinner = element.shadowRoot.querySelector('lightning-spinner');
        expect(spinner).not.toBeNull();
    });

    it('should reset form after successful task creation', async () => {
        getTasks.mockResolvedValue([]);
        createTask.mockResolvedValue({
            Id: '00T1234567890GHI',
            Subject: 'New Task',
            Status: 'Not Started',
            Priority: 'Normal'
        });

        const element = createElement('c-task-manager', {
            is: TaskManager
        });
        element.recordId = MOCK_ACCOUNT_ID;
        document.body.appendChild(element);

        await flushPromises();

        // Fill in the form
        const subjectInput = element.shadowRoot.querySelector('lightning-input[data-field="subject"]');
        subjectInput.value = 'New Task';
        subjectInput.dispatchEvent(new CustomEvent('change', { detail: { value: 'New Task' } }));

        const createButton = element.shadowRoot.querySelector('lightning-button');
        createButton.click();

        await flushPromises();

        // Check form is reset
        expect(element.newTaskSubject).toBe('');
    });
});