import Country from '../models/Country.model.js';

// 1. Get All Countries
export const getAllCountries = async (req, res) => {
    try {
        const countries = await Country.find().sort({ createdAt: -1 });
        res.status(200).json({ success: true, data: countries });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// 2. Create Country
export const createCountry = async (req, res) => {
    try {
        const { id, name, slug } = req.body;

        if (!name || !slug || !id) {
            return res.status(400).json({ success: false, message: 'ID, Name, and Slug are required' });
        }

        const newCountry = new Country({
            id, // Custom ID field from source
            name,
            slug
        });

        const savedCountry = await newCountry.save();
        res.status(201).json({ success: true, data: savedCountry });

    } catch (error) {
        if (error.code === 11000) {
            return res.status(400).json({ success: false, message: 'Country with this ID or Slug already exists' });
        }
        res.status(500).json({ success: false, message: error.message });
    }
};

// 3. Delete Country
export const deleteCountry = async (req, res) => {
    try {
        const { id } = req.params;
        // Note: We search by custom 'id' field, or _id? Model has 'id' field unique. 
        // Usually 'findById' looks for _id. If we want to find by 'id' field:
        const deletedCountry = await Country.findOneAndDelete({ id: id });
        // OR if Mongoose auto-cast, but 'id' is String here. 
        // Let's assume params 'id' matches the 'id' field of the schema.

        if (!deletedCountry) {
            return res.status(404).json({ success: false, message: 'Country not found' });
        }

        res.status(200).json({ success: true, message: 'Country deleted successfully' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
