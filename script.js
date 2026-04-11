(function () {
    const uploadArea = document.getElementById('uploadArea');
    const fileInput = document.getElementById('fileInput');
    const previewContainer = document.getElementById('previewContainer');
    const actions = document.getElementById('actions');
    const clearBtn = document.getElementById('clearBtn');

    const files = [];

    function isImage(file) {
        return file && file.type && file.type.startsWith('image/');
    }

    function renderPreviews() {
        previewContainer.innerHTML = '';

        files.forEach((file, index) => {
            const item = document.createElement('div');
            item.className = 'preview-item';

            const img = document.createElement('img');
            img.alt = file.name;
            const reader = new FileReader();
            reader.onload = (e) => {
                img.src = e.target.result;
            };
            reader.readAsDataURL(file);

            const name = document.createElement('div');
            name.className = 'file-name';
            name.textContent = file.name;

            const removeBtn = document.createElement('button');
            removeBtn.className = 'remove-btn';
            removeBtn.type = 'button';
            removeBtn.setAttribute('aria-label', '削除');
            removeBtn.textContent = '×';
            removeBtn.addEventListener('click', () => {
                files.splice(index, 1);
                renderPreviews();
            });

            item.appendChild(img);
            item.appendChild(name);
            item.appendChild(removeBtn);
            previewContainer.appendChild(item);
        });

        actions.hidden = files.length === 0;
    }

    function addFiles(fileList) {
        Array.from(fileList).forEach((file) => {
            if (isImage(file)) {
                files.push(file);
            }
        });
        renderPreviews();
    }

    fileInput.addEventListener('change', (e) => {
        addFiles(e.target.files);
        fileInput.value = '';
    });

    ['dragenter', 'dragover'].forEach((eventName) => {
        uploadArea.addEventListener(eventName, (e) => {
            e.preventDefault();
            e.stopPropagation();
            uploadArea.classList.add('dragover');
        });
    });

    ['dragleave', 'drop'].forEach((eventName) => {
        uploadArea.addEventListener(eventName, (e) => {
            e.preventDefault();
            e.stopPropagation();
            uploadArea.classList.remove('dragover');
        });
    });

    uploadArea.addEventListener('drop', (e) => {
        if (e.dataTransfer && e.dataTransfer.files) {
            addFiles(e.dataTransfer.files);
        }
    });

    clearBtn.addEventListener('click', () => {
        files.length = 0;
        renderPreviews();
    });
})();
