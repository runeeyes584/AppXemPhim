import mongoose from 'mongoose';

const CountrySchema = new mongoose.Schema({
    id: {
        type: String, // ID từ API nguồn (ví dụ: "aadd510492662beef1a980624b26c685")
        alias: '_id', // Map 'id' to '_id' access if needed, or just store as 'id' and usage standard _id? 
        // Mongoose requires _id. If source uses 'id', we can treat it as a custom field or map it.
        // For simplicity and to match JSON exactly, I'll keep 'id' as a field and let Mongoose generate _id or use this as _id.
        // But 'id' in Mongoose document usually is a getter for _id.
        // Let's explicitly define _id as String to match standard usage if we were to use it as primary key.
        // BUT, the sample json has "id".
        // To be safe, I will allow Mongoose to auto-generate _id if not provided, but I will index 'id' and 'slug'.
        // Or better: Use the provided ID as the _id to keep relationships intact easily?
        // The Country json has "id". The Category json has "_id".
        // I will map Country's `id` field to a String field `id` and also let `_id` be generated or explicitly set.
        // Standard practice for imported data: use the imported ID as `_id` if unique.
        required: true,
        unique: true
    },
    name: {
        type: String,
        required: true
    },
    slug: {
        type: String,
        required: true,
        unique: true
    }
}, {
    timestamps: true
});

const Country = mongoose.model('Country', CountrySchema);
export default Country;
